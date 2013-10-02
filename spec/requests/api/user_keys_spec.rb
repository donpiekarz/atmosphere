require 'spec_helper'

describe Api::V1::UserKeysController do
  include ApiHelpers

  let(:user)  { create(:user) }
  let(:admin) { create(:admin) }

  let!(:user_key1) { create(:user_key, user: user) }
  let!(:user_key2) { create(:user_key, user: user) }
  let!(:other_user_key) { create(:user_key) }

  describe 'GET /user_keys' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api('/user_keys')
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Success' do
        get api('/user_keys', user)
        expect(response.status).to eq 200
      end

      it 'returns all owned user keys' do
        get api('/user_keys', user)
        expect(user_keys_response).to be_an Array
        expect(user_keys_response.size).to eq 2

        expect(user_keys_response[0]).to user_key_eq user_key1
        expect(user_keys_response[1]).to user_key_eq user_key2
      end
    end

    context 'when authenticated as admin' do
      it 'returns all user keys when all flag is true' do
        get api('/user_keys?all=true', admin)
        expect(user_keys_response).to be_an Array
        expect(user_keys_response.size).to eq 3
      end
    end
  end

  describe 'GET /user_keys/{id}' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        get api("/user_keys/#{user_key1.id}")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      it 'returns 200 Success' do
        get api("/user_keys/#{user_key1.id}", user)
        expect(response.status).to eq 200
      end

      it 'returns owner user key' do
        get api("/user_keys/#{user_key1.id}", user)
        expect(user_key_response).to user_key_eq user_key1
      end

      it 'returns 403 Forbidden when getting not owned user key' do
        get api("/user_keys/#{other_user_key.id}", user)
        expect(response.status).to eq 403
      end
    end

    context 'when authenticated as admin' do
      it 'returns not owned user key' do
        get api("/user_keys/#{other_user_key.id}", admin)
        expect(response.status).to eq 200
      end
    end
  end

  describe 'POST /user_keys' do
    context 'when unauthenticated' do
      it 'returns 401 Unauthorized error' do
        post api("/user_keys")
        expect(response.status).to eq 401
      end
    end

    context 'when authenticated as user' do
      let(:new_key_request) do
        {
          user_key: {
            name: 'new_user_key',
            public_key: user_key1.public_key
          }
        }
      end

      it 'returns 201 Created on success' do
        post api("/user_keys", user), new_key_request
        expect(response.status).to eq 201
      end

      it 'adds new user key' do
        expect {
          post api("/user_keys", user), new_key_request
        }.to change { UserKey.count }.by(1)
      end

      it 'adds new user key and generate fingerprint' do
        post api("/user_keys", user), new_key_request
        added_user_key = UserKey.find(user_key_response['id'])
        expect(added_user_key.fingerprint).to eq user_key1.fingerprint
        expect(added_user_key.name).to eq new_key_request[:user_key][:name]
        expect(added_user_key.public_key).to eq new_key_request[:user_key][:public_key]
      end
    end
  end

  describe 'DELETE /user_key/{id}' do
    it 'returns 401 Unauthorized error' do
      delete api("/user_keys/#{user_key1.id}")
      expect(response.status).to eq 401
    end

    context 'when authenticated as user' do
      it 'returns 200 Success when deleting owned user key' do
        expect {
          delete api("/user_keys/#{user_key1.id}", user)
          expect(response.status).to eq 200
        }.to change { UserKey.count }.by(-1)
      end

      it 'returns 403 Forbidden when deleting not owned user key' do
        expect {
          delete api("/user_keys/#{other_user_key.id}", user)
          expect(response.status).to eq 403
        }.to change { UserKey.count }.by(0)
      end
    end

    context 'when authenticated as admin' do
      it 'allows to remove not owned user keys' do
        expect {
          delete api("/user_keys/#{other_user_key.id}", admin)
          expect(response.status).to eq 200
          }.to change { UserKey.count }.by(-1)
      end
    end
  end

  def user_keys_response
    json_response['user_keys']
  end

  def user_key_response
    json_response['user_key']
  end
end
