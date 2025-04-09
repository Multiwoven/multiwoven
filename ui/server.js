const express = require('express');
const path = require('path');
const fs = require('fs');
const app = express();

// Serve static files from the React app build directory
app.use(express.static(path.join(__dirname, 'dist')));

app.get('/env', (req, res) => {
  res.json({
    VITE_API_HOST: process.env.VITE_API_HOST,
  });
});

// Handles any requests that don't match the ones above
app.get(/(.*)/, (req, res) => {
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
