package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"os/exec"
	"time"
)

// JSONRequest representa la entrada de la API
type JSONRequest struct {
	Precision   int           `json:"precision"`
	Variables   []Variable    `json:"variables"`
	Expressions []Expression  `json:"expressions"`
}

type Variable struct {
	Name  string      `json:"name"`
	Type  string      `json:"type"`
	Value interface{} `json:"value"`
}

type Expression struct {
	Name    string `json:"name"`
	Formula string `json:"formula"`
}

// JSONResponse representa la salida de la API
type JSONResponse struct {
	Success bool        `json:"success"`
	Results interface{} `json:"results,omitempty"`
	Error   string      `json:"error,omitempty"`
}

const (
	bridgePath = "./bin/bridge"
	timeout    = 10 * time.Second
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// API endpoints
	http.HandleFunc("/health", handleHealth)
	http.HandleFunc("/evaluate", handleEvaluate)
	http.HandleFunc("/api/bison", handleEvaluate) // Alias para el hub
	http.HandleFunc("/api/info", handleRoot)

	// Servir archivos estáticos (página web)
	publicDir := "./public"
	if _, err := os.Stat(publicDir); err == nil {
		fs := http.FileServer(http.Dir(publicDir))
		http.Handle("/", fs)
		log.Printf("📁 Serving static files from %s\n", publicDir)
	} else {
		http.HandleFunc("/", handleRoot)
		log.Printf("⚠️  Public directory not found, using default handler\n")
	}

	log.Printf("🚀 GNUBison API Server starting on port %s\n", port)
	log.Printf("📍 Endpoints:")
	log.Printf("   GET  /             - Web UI (API Hub)")
	log.Printf("   GET  /health       - Health check")
	log.Printf("   GET  /api/info     - API information")
	log.Printf("   POST /evaluate     - Evaluate CSP expressions")
	log.Printf("   POST /api/bison    - Alias for /evaluate")

	if err := http.ListenAndServe(":"+port, enableCORS(http.DefaultServeMux)); err != nil {
		log.Fatal(err)
	}
}

func handleRoot(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"service": "GNUBison API",
		"version": "1.0",
		"endpoints": map[string]string{
			"GET /health":      "Health check",
			"POST /evaluate":   "Evaluate CSP expressions",
			"POST /api/bison":  "Alias for /evaluate",
		},
		"docs": "https://github.com/tu-repo/gnubison",
	})
}

func handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":    "ok",
		"service":   "GNUBison API",
		"timestamp": time.Now().Unix(),
	})
}

func handleEvaluate(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		sendError(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Leer body
	body, err := io.ReadAll(r.Body)
	if err != nil {
		sendError(w, "Failed to read request body", http.StatusBadRequest)
		return
	}
	defer r.Body.Close()

	// Validar JSON
	var req JSONRequest
	if err := json.Unmarshal(body, &req); err != nil {
		sendError(w, fmt.Sprintf("Invalid JSON: %v", err), http.StatusBadRequest)
		return
	}

	// Crear archivo temporal
	tmpFile, err := os.CreateTemp("", "gnubison-*.json")
	if err != nil {
		sendError(w, "Failed to create temp file", http.StatusInternalServerError)
		return
	}
	tmpPath := tmpFile.Name()
	defer os.Remove(tmpPath)

	// Escribir JSON al archivo temporal
	if _, err := tmpFile.Write(body); err != nil {
		tmpFile.Close()
		sendError(w, "Failed to write temp file", http.StatusInternalServerError)
		return
	}
	tmpFile.Close()

	// Ejecutar bridge
	result, err := executeBridge(tmpPath)
	if err != nil {
		sendError(w, fmt.Sprintf("Evaluation failed: %v", err), http.StatusInternalServerError)
		return
	}

	// Enviar resultado
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(JSONResponse{
		Success: true,
		Results: result,
	})
}

func executeBridge(inputPath string) (interface{}, error) {
	// Verificar que el ejecutable existe
	if _, err := os.Stat(bridgePath); os.IsNotExist(err) {
		return nil, fmt.Errorf("bridge executable not found at %s", bridgePath)
	}

	// Crear archivo de salida temporal
	outputFile, err := os.CreateTemp("", "gnubison-output-*.json")
	if err != nil {
		return nil, err
	}
	outputPath := outputFile.Name()
	outputFile.Close()
	defer os.Remove(outputPath)

	// Ejecutar: ./bin/bridge --json input.json -o output.json
	cmd := exec.Command(bridgePath, "--json", inputPath, "-o", outputPath)

	var stderr bytes.Buffer
	cmd.Stderr = &stderr

	// Ejecutar con timeout
	done := make(chan error, 1)
	go func() {
		done <- cmd.Run()
	}()

	select {
	case err := <-done:
		if err != nil {
			return nil, fmt.Errorf("bridge error: %v - %s", err, stderr.String())
		}
	case <-time.After(timeout):
		cmd.Process.Kill()
		return nil, fmt.Errorf("execution timeout after %v", timeout)
	}

	// Leer resultado
	output, err := os.ReadFile(outputPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read output: %v", err)
	}

	var result interface{}
	if err := json.Unmarshal(output, &result); err != nil {
		// Si no es JSON válido, devolver como texto
		return string(output), nil
	}

	return result, nil
}

func sendError(w http.ResponseWriter, message string, statusCode int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	json.NewEncoder(w).Encode(JSONResponse{
		Success: false,
		Error:   message,
	})
}

// enableCORS habilita CORS para permitir requests desde cualquier origen
func enableCORS(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")

		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}
