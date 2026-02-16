require('dotenv').config();

const express = require('express');
const cors = require('cors');

const app = express();
const port = Number(process.env.PORT || 8080);
const host = process.env.HOST || '0.0.0.0';
const corsOrigin = process.env.CORS_ORIGIN || '*';

app.use(
  cors({
    origin:
      corsOrigin === '*'
        ? '*'
        : corsOrigin
            .split(',')
            .map((value) => value.trim())
            .filter(Boolean),
  }),
);
app.use(express.json());

app.get('/', (_req, res) => {
  res.json({
    service: 'gre-backend-railway',
    status: 'running',
    message: 'Backend is live on Railway',
  });
});

app.get('/health', (_req, res) => {
  res.status(200).json({
    ok: true,
    uptimeSeconds: Math.floor(process.uptime()),
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development',
  });
});

app.get('/api/v1/status', (_req, res) => {
  res.json({
    api: 'v1',
    ready: true,
    notes: 'Replace this with real auth/courses/tests endpoints next.',
  });
});

app.use((req, res) => {
  res.status(404).json({
    error: 'Route not found',
    path: req.path,
  });
});

app.listen(port, host, () => {
  // eslint-disable-next-line no-console
  console.log(`API server listening on ${host}:${port}`);
});
