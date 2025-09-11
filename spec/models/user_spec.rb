# == Schema Information
#
# Table name: users
#
#  id              :bigint           not null, primary key
#  email           :string
#  name            :string
#  password_digest :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_email  (email) UNIQUE
#
require 'rails_helper'

RSpec.describe User, type: :model do
  it '有効なファクトリを持つ' do
    expect(build(:user)).to be_valid
  end

  describe 'バリデーション' do
    it 'name は必須' do
      u = build(:user, name: '')
      expect(u).to be_invalid
      expect(u.errors[:name]).to be_present
    end

    it 'email は必須' do
      u = build(:user, email: '')
      expect(u).to be_invalid
      expect(u.errors[:email]).to be_present
    end

    it 'メールはユニーク（大文字小文字を正規化）' do
      create(:user, email: 'foo@example.com')
      build(:user, email: 'Foo@Example.com')
      # バリデーションを迂回して DB 制約に当てる
      expect { create(:user, email: 'Foo@Example.com') }
        .to raise_error(ActiveRecord::RecordInvalid)
    end

    it '保存時にメールが小文字化される' do
      u = create(:user, email: 'Foo@Example.com')
      expect(u.reload.email).to eq('foo@example.com')
    end

    it 'パスワードは8文字以上' do
      u = build(:user, password: 'short', password_confirmation: 'short')
      expect(u).to be_invalid
      expect(u.errors[:password]).to be_present
    end
  end

  describe 'has_secure_password' do
    it '正しいパスワードで認証できる' do
      u = create(:user, password: 'password123', password_confirmation: 'password123')
      expect(u.authenticate('password123')).to be_truthy
      expect(u.authenticate('wrong')).to be_falsey
    end
  end
end
