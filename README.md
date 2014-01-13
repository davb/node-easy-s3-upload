# Easy S3 Uploader for Node.js

A middleware for Express/Connect to quickly set up forms
for your users to securely upload files to Amazon S3.


## Installation

Add the npm package to your app

```
npm install easy-s3-upload
```

Set the following environment variables to your AWS credentials:

```
AWS_ACCESS_KEY_ID=(your AWS access key id)
AWS_SECRET_KEY=(your AWS secret key)
AWS_ENDPOINT=(e.g. s3.amazonaws.com, must match your bucket region)
```


## Usage

Add the middleware to your Express or Connect stack:

```javascript
s3_uploader = require 'easy-s3-upload'

app.use(s3_uploader({
  form_url: 'http://yourapp.com/upload',
  success_action_redirect_url: 'http://yourapp.com/upload/success',
  bucket_name: 'your_bucket'
}))
```

Then navigate to `http://yourapp.com/upload` to see a basic working
upload form.


## Development

Run this to compile the CoffeeScript source:

```
coffee -cw -o lib/ src/
```
