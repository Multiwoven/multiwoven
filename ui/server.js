const express = require('express');
const path = require('path');
const fs = require('fs');
const https = require('https');
const app = express();

// Middleware to parse JSON bodies
app.use(express.json());

// Serve static files from the React app build directory
app.use(express.static(path.join(__dirname, 'dist')));

// API endpoints
app.get('/env', (req, res) => {
  res.json({
    VITE_API_HOST: process.env.VITE_API_HOST,
    VITE_FACEBOOK_APP_ID: process.env.VITE_FACEBOOK_APP_ID,
  });
});



// Facebook token exchange endpoint
app.post('/api/facebook/exchange-token', (req, res) => {
  try {
    const { shortLivedToken } = req.body;

    if (!shortLivedToken) {
      return res.status(400).json({ error: 'Short-lived token is required' });
    }

    // Use fallback values if environment variables are not set
    const appId = process.env.VITE_FACEBOOK_APP_ID || '1197322945393100';
    const appSecret = process.env.VITE_FACEBOOK_APP_SECRET || '8ee99fd14211357dc26948cba07845e5';

    const url = `https://graph.facebook.com/v17.0/oauth/access_token?` +
      `grant_type=fb_exchange_token&` +
      `client_id=${appId}&` +
      `client_secret=${appSecret}&` +
      `fb_exchange_token=${shortLivedToken}`;

    https.get(url, (fbRes) => {
      let data = '';

      fbRes.on('data', (chunk) => {
        data += chunk;
      });

      fbRes.on('end', () => {
        try {
          const parsedData = JSON.parse(data);

          if (parsedData.error) {
            return res.status(400).json({ error: parsedData.error });
          }

          res.json({ access_token: parsedData.access_token });
        } catch (parseError) {
          console.error('Error parsing Facebook response:', parseError);
          res.status(500).json({ error: 'Failed to parse Facebook response' });
        }
      });
    }).on('error', (httpError) => {
      console.error('Error making request to Facebook:', httpError);
      res.status(500).json({ error: 'Failed to connect to Facebook API' });
    });
  } catch (error) {
    console.error('Error exchanging Facebook token:', error);
    res.status(500).json({ error: 'Failed to exchange token' });
  }
});

// Last middleware to handle all other requests - this avoids using path-to-regexp's pattern matching
app.use((req, res) => {
  const indexPath = path.join(__dirname, 'dist', 'index.html');
  fs.readFile(indexPath, 'utf8', (err, data) => {
    if (err) {
      console.error('Error reading the index.html file', err);
      return res.status(500).send('An error occurred serving the application');
    }
    // Replace the placeholder in the HTML with the actual environment variable
    data = data.replace(/__VITE_API_HOST__/g, process.env.VITE_API_HOST);
    res.send(data);
  });
});

const port = process.env.PORT || 8000;
app.listen(port, () => {
  console.log(`Server is listening on port ${port}`);
});
