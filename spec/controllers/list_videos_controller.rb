require 'rails_helper'

RSpec.describe ListVideosController, :type => :controller do
  describe 'GET #status' do
    it 'returns success true' do
      get :status
      expect(response).to be_success
      expect(response).to have_http_status(200)
    end
  end
end
