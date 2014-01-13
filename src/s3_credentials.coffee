crypto = require 'crypto'
mime = require 'mime'
url = require 'url'


aws_secret_key = process.env['AWS_SECRET_KEY']
throw "missing AWS_SECRET_KEY environment variable" unless aws_secret_key

aws_access_key_id = process.env['AWS_ACCESS_KEY_ID']
throw "missing AWS_ACCESS_KEY_ID environment variable" unless aws_access_key_id


module.exports = (filename, opts, callback) ->
  opts['acl'] ?= 'public-read'
  mimetype = mime.lookup(filename)
  key = filename.split('/').slice(-1)[0].split('\\').slice(-1)[0]

  policy =
    expiration: new Date(new Date().getTime() + 30 * 60000).toISOString()
    conditions: [
      {bucket: opts['bucket_name']},
      #['starts-with', '$Content-Disposition', ''],
      ['eq', '$key', key],
      {'acl': opts['acl']},
      ['content-length-range', 0, 2147483648],
      ['eq', '$Content-Type', mimetype],
    ].concat(if opts['success_action_status']
      [{success_action_status: opts['success_action_status']}]
    else if opts['success_action_redirect']
      [{success_action_redirect: opts['success_action_redirect']}]
    else
      []
    )

  string_policy = JSON.stringify(policy)
  base64_policy = new Buffer(string_policy, 'utf-8').toString('base64')

  # sign the base64 encoded policy
  signature = crypto.createHmac('sha1', aws_secret_key)
    .update(new Buffer(base64_policy, 'utf-8')).digest('base64')

  credentials =
    policy: base64_policy
    signature: signature
    access_key_id: aws_access_key_id
    success_action_redirect: opts['success_action_redirect']
    success_action_status: opts['success_action_status']
    key: key
    content_type: mimetype
    acl: opts['acl']

  callback(credentials)