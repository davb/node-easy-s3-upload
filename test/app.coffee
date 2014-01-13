http = require 'http'
connect = require 'connect'
s3_upload = require '../lib/index'
url = require 'url'


host = process.env['HOST'] ? 'localhost'
port = parseInt process.env['PORT'] ? 5000, 10
host_with_port = "#{host}"
host_with_port += ':' + port unless port == 80


app = connect()
.use(connect.logger('dev'))
.use(s3 = s3_upload({
  success_action_redirect_url: "http://#{host_with_port}/s3/upload/success"
}))
.use (req, res) ->
  layout = (content) ->
    """
    <html>
      <head><title>Test s3 upload</title></head>
      <body>#{content}</body>
    </html>
    """
  parsed_url = url.parse(req.url, true)
  if parsed_url.pathname == '/s3/upload/success'
    res.end layout("File <b>#{parsed_url.query.key}</b> successfully uploaded on <b>#{parsed_url.query.bucket}</b>")
  else
    res.end layout("Please go <a href='#{s3.config.form_url}'>here</a> to test the file upload")

console.log "Test app listening on port #{port}"
http.createServer(app).listen(port)