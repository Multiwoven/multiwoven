const express = require('express');
const path = require('path');
const fs = require('fs');
const https = require('https');
const app = express();

// Middleware to parse JSON bodies
app.use(express.json());

// Serve static files from the React app build directory
app.use(express.static(path.join(__dirname, 'dist')));

// Facebook callback route
app.get('/auth/facebook/callback', (req, res) => {
  // This is just a placeholder page that will extract the token from the URL hash
  // and post it back to the opener window
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>Facebook Authentication</title>
    </head>
    <body>
      <h1>Authentication Complete</h1>
      <p>You can close this window now.</p>
      <script>
        // Extract access token from URL hash
        function getHashParams() {
          const hashParams = {};
          const hash = window.location.hash.substring(1);
          const params = hash.split('&');
          
          for (let i = 0; i < params.length; i++) {
            const [key, value] = params[i].split('=');
            hashParams[key] = decodeURIComponent(value);
          }
          
          return hashParams;
        }
        
        // Get the access token
        const params = getHashParams();
        const accessToken = params.access_token;
        
        if (accessToken) {
          // Send the token back to the opener window
          if (window.opener) {
            window.opener.postMessage({
              type: 'FACEBOOK_AUTH_SUCCESS',
              accessToken: accessToken
            }, window.location.origin);
            
            // Close this window
            setTimeout(() => window.close(), 1000);
          } else {
            document.body.innerHTML += '<p>Error: Could not communicate with the opener window.</p>';
          }
        } else {
          document.body.innerHTML += '<p>Error: No access token found in the URL.</p>';
        }
      </script>
    </body>
    </html>
  `);
});

// API endpoints
app.get('/env', (req, res) => {
  res.json({
    VITE_API_HOST: process.env.VITE_API_HOST,
    VITE_FACEBOOK_APP_ID: process.env.FACEBOOK_APP_ID,
  });
});

// Facebook token exchange endpoint - using a path that won't be proxied to Rails
app.post('/facebook-token-exchange', (req, res) => {
  try {
    const { shortLivedToken } = req.body;

    if (!shortLivedToken) {
      return res.status(400).json({ error: 'Short-lived token is required' });
    }

    // Use fallback values if environment variables are not set
    const appId = process.env.FACEBOOK_APP_ID;
    const appSecret = process.env.FACEBOOK_APP_SECRET;

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
app.use(/(.*)/,(req, res) => {
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
  
  // Log environment variables for debugging
  console.log('Environment variables:');
  console.log('VITE_API_HOST:', process.env.VITE_API_HOST);
  console.log('FACEBOOK_APP_ID:', process.env.FACEBOOK_APP_ID);
  console.log('FACEBOOK_APP_SECRET:', process.env.FACEBOOK_APP_SECRET ? 'Set' : 'Not set');
  console.log('NODE_ENV:', process.env.NODE_ENV);
});
