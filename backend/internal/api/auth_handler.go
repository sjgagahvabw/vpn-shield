package api

import (
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/vpn-shield/backend/internal/config"
	"github.com/vpn-shield/backend/internal/db"
	"github.com/vpn-shield/backend/internal/models"
	"golang.org/x/crypto/bcrypt"
)

type AuthHandler struct {
	db  *db.Database
	cfg *config.Config
}

func NewAuthHandler(database *db.Database, cfg *config.Config) *AuthHandler {
	return &AuthHandler{
		db:  database,
		cfg: cfg,
	}
}

type RegisterRequest struct {
	Username string `json:"username"`
	Email    string `json:"email"`
	Password string `json:"password"`
}

type LoginRequest struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

type AuthResponse struct {
	Token     string       `json:"token"`
	ExpiresAt time.Time    `json:"expires_at"`
	User      *models.User `json:"user"`
}

func (h *AuthHandler) Register(c *fiber.Ctx) error {
	var req RegisterRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Invalid request body",
		})
	}

	// Validate input
	if req.Username == "" || req.Email == "" || req.Password == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Username, email and password are required",
		})
	}
	
	// Validate username length
	if len(req.Username) < 3 || len(req.Username) > 50 {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Username must be between 3 and 50 characters",
		})
	}
	
	// Validate password strength
	if len(req.Password) < 8 {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Password must be at least 8 characters long",
		})
	}
	
	// Basic email validation
	if !strings.Contains(req.Email, "@") || !strings.Contains(req.Email, ".") {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Invalid email format",
		})
	}

	// Check if user exists
	if _, err := h.db.GetUserByUsername(req.Username); err == nil {
		return c.Status(fiber.StatusConflict).JSON(fiber.Map{
			"error": "Username already exists",
		})
	}

	if _, err := h.db.GetUserByEmail(req.Email); err == nil {
		return c.Status(fiber.StatusConflict).JSON(fiber.Map{
			"error": "Email already exists",
		})
	}

	// Hash password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to hash password",
		})
	}

	// Create user
	user := &models.User{
		ID:             uuid.New(),
		Username:       req.Username,
		Email:          req.Email,
		Password:       string(hashedPassword),
		IsAdmin:        false,
		IsActive:       true,
		DataLimit:      0, // unlimited
		MaxDevices:     5,
		EnableREALITY:  true,
		EnableHysteria: true,
		EnableTrojan:   true,
		EnableVMess:    true,
		EnableNaive:    false,
	}

	if err := h.db.CreateUser(user); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to create user",
		})
	}

	// Generate token
	token, expiresAt, err := h.generateToken(user)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to generate token",
		})
	}

	// Audit log
	h.db.CreateAuditLog(&models.AuditLog{
		UserID:    &user.ID,
		Action:    "user_registered",
		Resource:  "auth",
		Details:   "User registered: " + user.Username,
		IPAddress: c.IP(),
		UserAgent: c.Get("User-Agent"),
	})

	return c.Status(fiber.StatusCreated).JSON(AuthResponse{
		Token:     token,
		ExpiresAt: expiresAt,
		User:      user,
	})
}

func (h *AuthHandler) Login(c *fiber.Ctx) error {
	var req LoginRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": "Invalid request body",
		})
	}

	// Get user
	user, err := h.db.GetUserByUsername(req.Username)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "Invalid credentials",
		})
	}

	// Check if user is active
	if !user.IsActive {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"error": "Account is disabled",
		})
	}

	// Verify password
	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.Password)); err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "Invalid credentials",
		})
	}

	// Generate token
	token, expiresAt, err := h.generateToken(user)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to generate token",
		})
	}

	// Audit log
	h.db.CreateAuditLog(&models.AuditLog{
		UserID:    &user.ID,
		Action:    "user_login",
		Resource:  "auth",
		Details:   "User logged in: " + user.Username,
		IPAddress: c.IP(),
		UserAgent: c.Get("User-Agent"),
	})

	return c.JSON(AuthResponse{
		Token:     token,
		ExpiresAt: expiresAt,
		User:      user,
	})
}

func (h *AuthHandler) RefreshToken(c *fiber.Ctx) error {
	// Get user from context (set by middleware)
	userID := c.Locals("user_id").(string)

	user, err := h.db.GetUserByID(userID)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "User not found",
		})
	}

	// Generate new token
	token, expiresAt, err := h.generateToken(user)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to generate token",
		})
	}

	return c.JSON(AuthResponse{
		Token:     token,
		ExpiresAt: expiresAt,
		User:      user,
	})
}

func (h *AuthHandler) GetCurrentUser(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(string)

	user, err := h.db.GetUserByID(userID)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "User not found",
		})
	}

	return c.JSON(user)
}

func (h *AuthHandler) generateToken(user *models.User) (string, time.Time, error) {
	expiresAt := time.Now().Add(time.Hour * time.Duration(h.cfg.JWT.Expiration))

	claims := jwt.MapClaims{
		"user_id":  user.ID.String(),
		"username": user.Username,
		"email":    user.Email,
		"is_admin": user.IsAdmin,
		"exp":      expiresAt.Unix(),
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString([]byte(h.cfg.JWT.Secret))
	if err != nil {
		return "", time.Time{}, err
	}

	return tokenString, expiresAt, nil
}
