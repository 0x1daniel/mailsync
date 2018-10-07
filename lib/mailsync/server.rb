# MIT License
#
# Copyright (c) 2018 Daniel Oltmanns
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
require 'sinatra/base'
require 'bcrypt'

module MailSync
    class Server < Sinatra::Base
        configure do
            set :bind, '0.0.0.0'
            set :port, 8080
            set :public_folder, 'static'
            set :views, 'views'
            set :db, nil

            enable :sessions
        end

        before do
            @message = session[:message]
            session[:message] = nil

            @auth = session[:auth]
            @user = session[:user] if @auth
        end

        # GET Routes
        get '/' do
            require_guest
            erb :index
        end

        get '/board' do
            require_user
            erb :board
        end

        # POST routes
        post '/auth' do
            require_guest
            username = params[:username]
            password = params[:password]
            user = db.get_user_by_name username

            if user
                if BCrypt::Password.new(user['password']) == password
                    flash 'info', 'welcome back'
                    session[:auth] = true
                    session[:user] = user['id']
                    redirect '/board'
                    return
                end
            end

            flash 'error', 'wrong credentials'
            redirect '/'
        end

        # Helper functions
        def self.set_db=(db)
            settings.db = db
        end

        private

        def db
            raise 'no database' if settings.db.nil?
            settings.db
        end

        def require_user
            if !@auth
                flash 'error', 'please login to proceed'
                redirect '/'
            end
        end

        def require_guest
            redirect '/board' if @auth
        end

        def flash(type, content)
            session[:message] = {
                type: type,
                content: content
            }
        end
    end
end
