# ONE container for the whole project: builds the React frontend, then serves it
# from the FastAPI backend. Put this file in the PROJECT ROOT (next to backend/ and frontend/).

# ---- Stage 1: build the website ----
FROM node:22 AS web
WORKDIR /web
COPY frontend/package*.json ./
RUN npm install
COPY frontend/ .
# Empty API address = the site calls the backend on its own address (same origin, no CORS)
RUN echo "VITE_API_BASE=" > .env.production
RUN npm run build

# ---- Stage 2: backend + built website ----
# If pip cannot find your TensorFlow version for this Python version, change 3.11 (3.11 to 3.13 usually work).
FROM python:3.11-slim
WORKDIR /app
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY backend/app.py .
COPY backend/models ./models
COPY --from=web /web/dist ./static

# Hugging Face Spaces uses port 7860. Other hosts set PORT themselves.
ENV PORT=7860
EXPOSE 7860
CMD ["sh", "-c", "uvicorn app:app --host 0.0.0.0 --port ${PORT}"]
