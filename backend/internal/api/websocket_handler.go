package api

import (
	"log"
	"strings"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/websocket/v2"
	"github.com/golang-jwt/jwt/v5"
	"github.com/vpn-shield/backend/internal/db"
)

func NewWebSocketHandler(database *db.Database, jwtSecret string) fiber.Handler {
	return func(c *fiber.Ctx) error {
		// Validate JWT token from query parameter or header
		var tokenString string
		
		// Try to get token from query parameter first
		tokenString = c.Query("token")
		
		// If not in query, try Authorization header
		if tokenString == "" {
			authHeader := c.Get("Authorization")
			if authHeader != "" {
				parts := strings.Split(authHeader, " ")
				if len(parts) == 2 && parts[0] == "Bearer" {
					tokenString = parts[1]
				}
			}
		}
		
		if tokenString == "" {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error": "Missing authentication token",
			})
		}
		
		// Parse and validate token
		token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
			return []byte(jwtSecret), nil
		})
		
		if err != nil || !token.Valid {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error": "Invalid or expired token",
			})
		}
		
		// Extract user_id from claims
		var userID string
		if claims, ok := token.Claims.(jwt.MapClaims); ok {
			if uid, ok := claims["user_id"].(string); ok {
				userID = uid
			}
		}
		
		if userID == "" {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error": "Invalid token claims",
			})
		}
		
		// Upgrade to WebSocket
		if websocket.IsWebSocketUpgrade(c) {
			return websocket.New(func(conn *websocket.Conn) {
				log.Printf("WebSocket connected: user_id=%s", userID)

				defer func() {
					log.Printf("WebSocket disconnected: user_id=%s", userID)
					conn.Close()
				}()

				// Send initial connection message
				if err := conn.WriteJSON(fiber.Map{
					"type":    "connected",
					"message": "WebSocket connection established",
					"user_id": userID,
				}); err != nil {
					log.Printf("Error sending initial message: %v", err)
					return
				}

				// Listen for messages
				for {
					messageType, message, err := conn.ReadMessage()
					if err != nil {
						if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
							log.Printf("WebSocket error: %v", err)
						}
						break
					}

					log.Printf("Received message: type=%d, message=%s", messageType, message)

					// Echo back for now
					if err := conn.WriteMessage(messageType, message); err != nil {
						log.Printf("Error writing message: %v", err)
						break
					}
				}
			})(c)
		}
		
		return c.Status(fiber.StatusUpgradeRequired).JSON(fiber.Map{
			"error": "WebSocket upgrade required",
		})
	}
}
