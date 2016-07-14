# encoding: utf-8

class ContentUploader < CarrierWave::Uploader::Base
  storage :fog
end
