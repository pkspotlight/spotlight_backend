def get_s3_bucket
  Aws.config.update({
                      region: "us-east-1",
                      credentials: Aws::Credentials.new(ENV['aws_access_key_id'],
                                                        ENV['aws_secret_access_key'])
                    })

  Aws::S3::Resource.new.bucket(ENV['aws_s3_bucket_name'])
end

$aws = Aws.config.update({region: 'us-east-1',
                          credentials: Aws::Credentials.new(ENV['aws_access_key_id'],
                                                            ENV['aws_secret_access_key'])})
$s3 = Aws::S3::Resource.new(region: 'us-east-1')
$s3_bucket = $s3.bucket('spotlight-temp-bucket')
