package api

import (
	"log"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/websocket/v2"
	"github.com/vpn-shield/backend/internal/db"
)

func NewWebSocketHandler(database *db.Database) fiber.Handler {
	return websocket.New(func(c *websocket.Conn) {
		// Get user info from query params (passed after auth)
		userID := c.Query("user_id")
		if userID == "" {
			c.Close()
			return
		}

		log.Printf("WebSocket connected: user_id=%s", userID)

		defer func() {
			log.Printf("WebSocket disconnected: user_id=%s", userID)
			c.Close()
		}()

		// Send initial connection message
		if err := c.WriteJSON(fiber.Map{
			"type":    "connected",
			"message": "WebSocket connection established",
		}); err != nil {
			log.Printf("Error sending initial message: %v", err)
			return
		}

		// Listen for messages
		for {
			messageType, message, err := c.ReadMessage()
			if err != nil {
				if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
					log.Printf("WebSocket error: %v", err)
				}
				break
			}

			log.Printf("Received message: type=%d, message=%s", messageType, message)

			// Echo back for now
			if err := c.WriteMessage(messageType, message); err != nil {
				log.Printf("Error writing message: %v", err)
				break
			}
		}
	})
}
