package api

import (
	"github.com/gofiber/fiber/v2"
	"github.com/vpn-shield/backend/internal/config"
	"github.com/vpn-shield/backend/internal/db"
)

func SetupRoutes(app *fiber.App, database *db.Database, cfg *config.Config) {
	api := app.Group("/api")

	// Auth routes
	auth := api.Group("/auth")
	authHandler := NewAuthHandler(database, cfg)
	auth.Post("/register", authHandler.Register)
	auth.Post("/login", authHandler.Login)
	auth.Post("/refresh", authHandler.RefreshToken)
	auth.Get("/me", AuthMiddleware(cfg.JWT.Secret), authHandler.GetCurrentUser)

	// User routes
	users := api.Group("/users", AuthMiddleware(cfg.JWT.Secret))
	userHandler := NewUserHandler(database)
	users.Get("/", AdminMiddleware(), userHandler.GetAllUsers)
	users.Get("/:id", userHandler.GetUser)
	users.Put("/:id", userHandler.UpdateUser)
	users.Delete("/:id", AdminMiddleware(), userHandler.DeleteUser)
	users.Get("/:id/stats", userHandler.GetUserStats)

	// Config routes
	configs := api.Group("/configs", AuthMiddleware(cfg.JWT.Secret))
	configHandler := NewConfigHandler(database, cfg)
	configs.Get("/", configHandler.GetUserConfigs)
	configs.Post("/", configHandler.CreateConfig)
	configs.Get("/:id", configHandler.GetConfig)
	configs.Put("/:id", configHandler.UpdateConfig)
	configs.Delete("/:id", configHandler.DeleteConfig)
	configs.Get("/:id/qr", configHandler.GetQRCode)
	configs.Get("/:id/export", configHandler.ExportConfig)

	// Connection routes
	connections := api.Group("/connections", AuthMiddleware(cfg.JWT.Secret))
	connHandler := NewConnectionHandler(database)
	connections.Get("/", connHandler.GetUserConnections)
	connections.Get("/active", AdminMiddleware(), connHandler.GetActiveConnections)
	connections.Delete("/:id", connHandler.DisconnectConnection)

	// Server routes
	servers := api.Group("/servers", AuthMiddleware(cfg.JWT.Secret))
	serverHandler := NewServerHandler(database)
	servers.Get("/", serverHandler.GetServers)
	servers.Get("/:id", serverHandler.GetServer)
	servers.Post("/", AdminMiddleware(), serverHandler.CreateServer)
	servers.Put("/:id", AdminMiddleware(), serverHandler.UpdateServer)
	servers.Delete("/:id", AdminMiddleware(), serverHandler.DeleteServer)
	servers.Get("/:id/status", serverHandler.GetServerStatus)

	// Stats routes
	stats := api.Group("/stats", AuthMiddleware(cfg.JWT.Secret))
	statsHandler := NewStatsHandler(database)
	stats.Get("/", AdminMiddleware(), statsHandler.GetStats)
	stats.Get("/dashboard", AdminMiddleware(), statsHandler.GetDashboard)
	stats.Get("/traffic", AdminMiddleware(), statsHandler.GetTrafficStats)

	// Protocol management routes
	protocols := api.Group("/protocols", AuthMiddleware(cfg.JWT.Secret), AdminMiddleware())
	protocolHandler := NewProtocolHandler(database, cfg)
	protocols.Get("/xray/status", protocolHandler.GetXrayStatus)
	protocols.Post("/xray/restart", protocolHandler.RestartXray)
	protocols.Get("/hysteria/status", protocolHandler.GetHysteriaStatus)
	protocols.Post("/hysteria/restart", protocolHandler.RestartHysteria)
	protocols.Get("/test", protocolHandler.TestProtocols)

	// Audit logs
	audit := api.Group("/audit", AuthMiddleware(cfg.JWT.Secret), AdminMiddleware())
	auditHandler := NewAuditHandler(database)
	audit.Get("/", auditHandler.GetAuditLogs)

	// WebSocket for real-time updates
	app.Get("/ws", AuthMiddleware(cfg.JWT.Secret), NewWebSocketHandler(database))
}

// ErrorHandler handles all errors
func ErrorHandler(c *fiber.Ctx, err error) error {
	code := fiber.StatusInternalServerError

	if e, ok := err.(*fiber.Error); ok {
		code = e.Code
	}

	return c.Status(code).JSON(fiber.Map{
		"error": err.Error(),
		"code":  code,
	})
}
