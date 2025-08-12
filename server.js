// server.js
const express = require('express');
const app = express();

// const PORT = 3000;
const PORT = process.env.PORT || 3000;
const BG_COLOR = process.env.BG_COLOR || 'white';

app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
      <head>
        <title>SPA Example</title>
        <style>
          body {
            background-color: ${BG_COLOR};
            color: white;
            font-size: 2em;
            text-align: center;
            margin-top: 20vh;
            font-family: Arial, sans-serif;
          }
        </style>
      </head>
      <body>
        <h1>Hello</h1>
        <p>Background color is <strong>${BG_COLOR}</strong></p>
      </body>
    </html>
  `);
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}, background color: ${BG_COLOR}`);
});
