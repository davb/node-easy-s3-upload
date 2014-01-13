url = require 'url'
path = require 'path'
s3_credentials = require './s3_credentials'


prefixed_url = (prefix, rel_url) ->
  parsed = url.parse(rel_url)
  # if we have an absolute URL already, return it.
  return rel_url if parsed.protocol
  # We have a relative URL.
  # Prepend the prefix if any
  sep = if rel_url[0] == '/' then '' else '/'
  path.resolve prefix, '.' + sep + rel_url


form_script = (form_id, get_credentials_url) ->
  """
  <script type="text/javascript">
  $(document).ready(function() {
    var $form = $('form##{form_id}');
    $form.submit(function(event) {
      if ($form.find('input[name="signature"]').val().length) return true;
      event.preventDefault();
      var file = $form.find(
        'input[type="file"]').val().replace(/.+[\\\/]/, "");
      $.ajax({
        url: '#{get_credentials_url}?filename=' + file,
        dataType: 'jsonp',
        success: function(res) {
          console.log('s3 get credentials success', res);
          $form.find('input[name="AWSAccessKeyId"]').val(res.access_key_id);
          $form.find('input[name="policy"]').val(res.policy);
          $form.find('input[name="key"]').val(res.key);
          $form.find('input[name="acl"]').val(res.acl);
          $form.find('input[name="signature"]').val(res.signature);
          $form.find('input[name="Content-Type"]').val(res.content_type);
          $form.submit();
        },
        error: function(res, status, error) {
          console.log('s3 get credentials failed', status, error);
        },
      })
    });
  });
  </script>
  """


form_html = (bucket_name, opts = {}) ->
  opts['aws_endpoint'] ?= process.env['AWS_ENDPOINT'] ? 'amazonaws.com'
  opts['form_id'] ?= 's3_upload'
  get_credentials_url = prefixed_url opts['url_prefix'],
    opts['get_credentials_url']
  success_input = if opts['success_action_status']
    "<input type=\"hidden\" name=\"success_action_status\" value=\"#{opts['success_action_status']}\" />"
  else if opts['success_action_redirect']
    "<input type=\"hidden\" name=\"success_action_redirect\" value=\"#{opts['success_action_redirect']}\" />"
  else
    ""
  # return form HTML prepended with Javascript
  """
  #{form_script(opts['form_id'], get_credentials_url)}
  <form action="http://#{bucket_name}.#{opts['aws_endpoint']}/" method="post"
      enctype="multipart/form-data" id="#{opts['form_id']}">
    <input type="hidden" name="key" />
    <input type="hidden" name="AWSAccessKeyId" />
    <input type="hidden" name="acl" />
    <input type="hidden" name="policy" />
    <input type="hidden" name="signature" />
    <input type="hidden" name="Content-Type" />
    #{success_input}

    <input type="file" name="file" id="file" />
    <input type="submit" name="submit" value="Upload" />
  </form>
  """


default_form_html_wrapper = (form_html) ->
  """
  <html>
    <head>
      <title>Upload file</title>
      <script src="http://code.jquery.com/jquery-1.10.1.min.js"></script>
    </head>
    <body>
      <h1>Upload file</h1>
      #{form_html}
    </body>
  </html>
  """


jsonp_wrapper = (json, callback) ->
  callback ?= 'callback'
  "window.#{callback} && window.#{callback}(#{JSON.stringify(json)});"


module.exports = (opts = {}) ->
  opts['success_action_status'] ?= '201' unless opts['success_action_redirect']
  opts['form_url'] ?= '/s3/upload'
  opts['get_credentials_url'] ?= '/s3/get-credentials'
  opts['bucket_name'] ?= process.env['S3_UPLOAD_BUCKET']
  throw "ERROR missing parameter 'bucket_name'" unless opts['bucket_name']
  form_html_wrapper = opts['form_html_wrapper'] ? default_form_html_wrapper
  upload_form_pathname = opts['form_url'] &&
    url.parse(opts['form_url']).pathname
  get_credentials_pathname = opts['get_credentials_url'] &&
    url.parse(opts['get_credentials_url']).pathname
  # middleware
  middleware =
    # request handler function
    handle: (req, res, next) ->
      # parse URL
      request_url = url.parse(req.url, true)
      # set URL prefix if not set by comparing url and originalUrl
      opts['url_prefix'] ?= middleware.route || '/'
      # match pathname to handle request
      pathname = request_url.pathname
      if pathname == get_credentials_pathname
        # get credentials
        res.setHeader 'Content-Type', 'text/javascript'
        if filename = request_url.query['filename']
          s3_credentials filename, opts, (credentials) ->
            res.end jsonp_wrapper credentials, request_url.query['callback']
        else
          res.writeHead 400, 'Missing filename'
          res.end()
      else if pathname == upload_form_pathname
        # render form
        res.setHeader 'Content-Type', 'text/html'
        res.end form_html_wrapper form_html(opts['bucket_name'], opts)
      else
        next()
    # attach config to middleware
    config: opts
  # return middleware
  middleware
