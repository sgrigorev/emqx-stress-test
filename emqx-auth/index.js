'use strict';
const express = require('express'),
  bodyParser = require('body-parser'),
  winston = require('winston'),
  expressWinston = require('express-winston');

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.simple(),
  transports: [
    new winston.transports.Console()
  ]
});
const ACCESS_TYPES = {
  SUBSCRIBE: '1',
  PUBLISH: '2'
};
const port = parseInt(process.env.PORT) || 8000;
const app = express();

app.use(bodyParser.urlencoded({extended: false}));
app.use(expressWinston.logger({
  level: 'debug',
  winstonInstance: logger,
  meta: false,
  metaField: null,
  msg: '{{req.method}} {{req.url}} {{res.statusCode}} - {{res.responseTime}} ms'
}));

app.post('/mqtt/auth', (req, res) => {
  res.status(200).end();
});

app.post('/mqtt/superuser', (req, res) => {
  res.status(401).end();
});

app.post('/mqtt/acl', (req, res) => {
  res.status(200).end();
});

const server = app.listen(port, () => logger.info(`EMQX auth listening on port ${port}!`));

function shutDown() {
  logger.info('Received kill signal, shutting down gracefully');

  const timer = setTimeout(() => {
    logger.error('Could not close connections in time, forcefully shutting down');
    process.exit(1);
  }, 10000);

  server.close(() => {
    logger.info('Closed out remaining connections');
    clearTimeout(timer);
    process.exit(0);
  });
}

process.on('SIGTERM', shutDown);
process.on('SIGINT', shutDown);
