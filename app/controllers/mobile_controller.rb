class MobileController < ApplicationController
	def index
		regTypes={"Default" => 0,"NeedAccept" => 1,"FromFile" => 2}
		regNums={0 => "Default",1 => "NeedAccept",2 => "FromFile"}
		#sugStates{nil => "InProcess",1 => "Accepted",2 => "Rejected"}
		task = params[:task]
		if task == "signup"
			res={:ok => false}
			unless User.find_by_email(params[:username])
				u=User.create(:email => params[:username] , :password => params[:password] , :password_confirmation => params[:password],:reputation => 1)
				#token = r_token
				#t=Token.new(:auth_token => token)
				#t.user=u
				#t.save
				res={:ok => true,:cookie => {:username => u.email , :password => u.encrypted_password},:Exception => "null"}
			else
				res[:Exception]="DuplicateUsername"
			end
			respond_to do |format|
				format.json  { render json: res}
			end
			return
		end
		if task == "login"
			res={:ok => false,:Exception => "null"}
			u=User.find_by_email(params[:username])

			if u && u.valid_password?(params[:password])
				#token = r_token
				#t=Token.new(:auth_token => token)
				#t.user=u
				#t.save
				res={:ok => true,:cookie => {:username => u.email , :password => u.encrypted_password},:Exception => "null"}
			end
			respond_to do |format|
				format.json  { render json: res}
			end
			return
		end
		unless user=User.where(:email => params[:cookie][:username],:encrypted_password =>params[:cookie][:password])[0]
			respond_to do |format|
				format.json  { render json: {:Exception => "AuthenticationError"}}
			end
			return
		end
		if task == "createOrg"
			org=params[:org]
			newOrg=Organization.new(:content => org[:desc],:title => org[:name],:reg_type =>regTypes[org[:regType]])
			newOrg.user=user
			newOrg.save
			unless org[:picture] == ""
				File.open("assets/images/"+newOrg.id.to_s, "w") { |file| file.write org[:picture] }
				newOrg.update(:image_address => "assets/images/"+newOrg.id.to_s)
			end
			unless org[:fileAddress] == ""
				File.open("assets/files/"+newOrg.id.to_s, "w") { |file| file.write org[:fileAddress] }
				newOrg.update(:reg_file_address => "assets/files/"+newOrg.id.to_s)
			end
			respond_to do |format|
				format.json  { render json: {:Exception => "null",:ok => true}}
			end	
			return
		end
		if task == "getUserOrgs"
			orgs=Organization.all
			ids=Array.new
			orgs.each do |o|
				if o.user_id==user.id || o.users.include?(user)
					ids << o.id
				end
			end
			respond_to do |format|
				format.json  { render json: {:Exception => "null",:orgs => ids}}
			end
			return
		end
		if task == "getOrgInfo"
			org=Organization.find_by_id(params[:orgID])
			if org
				if org.user == user
					notif_count = Request.where(:organization_id => org.id,:answer => -1).size
				else
					notif_count = 0
					QuestionsUsers.where(:user_id => user.id,:option_num => -1).each do |qu|
						notif_count = notif_count + 1 if (qu.question.suggestion && qu.question.suggestion.organization == org)
					end
				end
				res={:Exception => "null",:name => org.title,:picAddress => org.image_address,:desc => org.content,:asManager => org.user==user,:notifCount => notif_count,:registerType => regNums[org.reg_type]}
			else
				res={:Exception => "NoIDFound"}
			end
			respond_to do |format|
				format.json  { render json: res}
			end
			return
		end
		if task == "suggest"
			org=Organization.find_by_id(params[:orgID])
			if org
				sug=Suggestion.new(:content => params[:suggestion])
				sug.organization=org
				sug.user=user
				sug.save
				send_to_users(user,sug)
				res={:Exception => "null"}
			else
				res={:Exception => "NoIDFound"}
			end
			respond_to do |format|
				format.json  { render json: res}
			end
			return
		end
		if task == "enrollInOrg"
			org=Organization.find_by_id(params[:orgID])
			if not org
				res={:Exception => "NoIDFound"}
			elsif org.user == user || org.users.include?(user)
				res={:Exception => "InvalidRequest"}
			elsif Request.where(:user_id => user,:organization_id => org.id, :answer => -1).size > 0
				res={:Exception => "InvalidRequest"}
			else
				res={:Exception => "null"}
				case org.reg_type
				when 0
					org.users << user
					res[:state]="OK"
				when 1
					req=Request.new
					req.user=user
					req.organization=org
					req.answer=-1
					req.save
					res[:state]="waitForAccept"
				when 2
					####TODO
				end
			end
			respond_to do |format|
				format.json  { render json: res}
			end
		end
		if task == "searchOrgs"
			orgs=Organization.where("title LIKE '%#{params[:expression]}%' OR content LIKE '%#{params[:expression]}%'")
			ids=Array.new
			orgs.each do |o|
				ids << o.id
			end
			respond_to do |format|
				format.json  { render json: {:Exception => "null",:orgs => ids}}
			end
			return
		end
		if task == "getMySuggestion"
			org=Organization.find_by_id(params[:orgID])
			unless org
				respond_to do |format|
					format.json  { render json: {:Exception => "NoIDFound"}}
				end
				return	
			end
			sugs=Array.new
			org.suggestions.order("id").each do |s|
				state=get_suggestion_state(s)
				if s.user==user || org.user==user || s.question.questions_users.include?(user) || state == "Accepted"
					sugs<<{"ID"=>s.id,"text"=>s.content,"state"=>state}
				end
			end
			respond_to do |format|
				format.json  { render json: {:Exception => "null",:suggestions => sugs}}
			end
			return
		end
		if task == "createSurvey"
			org=Organization.find_by_id(params[:orgID])
			unless org
				respond_to do |format|
					format.json  { render json: {:Exception => "NoIDFound"}}
				end
				return	
			end
			survey=Survey.new(:subject => params[:subject])
			survey.user=user
			survey.organization=org
			survey.save
			res={:Exception => "null"}
			qs=params[:questions]
			unless qs
				survey.destroy
				res[:Exception]="InvalidSurvey"
			end
			qs.each do |q|
				quest=Question.new(:content => q[:text])
				quest.survey=survey
				options=q[:options]
				unless options
					survey.destroy
					res[:Exception]="InvalidSurvey"
					break
				end
				options.each do |o|
					op=Option.new(:content => o)
					op.question=quest
					op.save
				end
				#quest.options.concat(options)
				quest.save
			end
			respond_to do |format|
				format.json  { render json: res}
			end	
			return	
		end
		if task == "getOrgsSurveys"
			org=Organization.find_by_id(params[:orgID])
			unless org
				respond_to do |format|
					format.json  { render json: {:Exception => "NoIDFound"}}
				end
				return	
			end
			ids=Array.new
			Survey.all.each do |s|
				ids << s.id
			end
			respond_to do |format|
				format.json  { render json: {:Exception => "null",:surveys => ids}}
			end		
			return	
		end
		if task == "getSurveyInfo"
			survey=Survey.find_by_id(params[:surveyID])
			if survey
				res={:Exception => "null",:orgID => survey.organization.id,:text => survey.subject,:date => survey.expire_date.to_f}
				q_ids=Array.new
				survey.questions.each do |q|
					q_ids << q.id
				end
				res[:questions]=q_ids
			else
				res={:Exception => "NoIDFound"}
			end
			respond_to do |format|
				format.json  { render json: res}
			end
			return
		end
		if task == "getQuestionInfo"
			quest=Question.find_by_id(params[:questionID])
			if quest
				x=QuestionsUsers.where(:question_id => quest.id,:user_id => user.id)[0]
				res={:Exception => "null",:text => quest.content,:chosen => (x ? x.option_num : -1) }
				ops=Array.new
				quest.options.each do |o|
					ops << o.content
				end
				res[:options]=ops
			else
				res={:Exception => "NoIDFound"}
			end
			respond_to do |format|
				format.json  { render json: res}
			end
			return
		end
		if task == "vote"
			survey=Survey.find_by_id(params[:surveyID])
			if survey.user == user
				respond_to do |format|
					format.json  { render json: {:Exception => "InvalidRequest"}}
				end
				return
			end
			if survey
				q_ids=params[:questions]
				o_ids=params[:options]
				q_ids.each_with_index do |id,i|
					qo=QuestionsUsers.create(:user_id => user.id,:question_id => id) unless qo=QuestionsUsers.where(:user_id => user.id,:question_id => id)[0]
					qo.update(:option_num => o_ids[i])
				end
				res={:Exception => "null"}
			else
				res={:Exception => "NoIDFound"}
			end
			respond_to do |format|
				format.json  { render json: res}
			end
			return
		end
		if task == "getQuestionResult"
			question=Question.find_by_id(params[:questionID])
			if question.survey.user != user
				respond_to do |format|
					format.json  { render json: {:Exception => "InvalidRequest"}}
				end
				return
			end
			if question
				q=question
				ops=Array.new(q.options.size)
				(0..ops.size-1).each do |i|
					ops[i]=QuestionsUsers.where(:question_id => q.id , :option_num => i).size
				end
				res={:Exception => "null",:options => ops}
			else
				res={:Exception => "NoIDFound"}
			end
			respond_to do |format|
				format.json  { render json: res}
			end
			return
		end
		if task == "getAskedSuggestions"
			org=Organization.find_by_id(params[:orgID])
			unless org
				respond_to do |format|
					format.json  { render json: {:Exception => "NoIDFound"}}
				end
				return	
			end
			sugs=Array.new
			QuestionsUsers.where(:user_id => user.id,:option_num => -1).each do |q|
				sugs << {:ID => q.question.suggestion.id, :text => q.question.suggestion.content,:state => "InProcess"} if q.question.suggestion
			end
			respond_to do |format|
				format.json  { render json: {:Exception => "null",:suggestions => sugs}}
			end
			return
		end
		if task == "getEnrollRequests"
			org=Organization.find_by_id(params[:orgID])
			unless org
				respond_to do |format|
					format.json  { render json: {:Exception => "NoIDFound"}}
				end
				return	
			end
			unless org.user == user
				respond_to do |format|
					format.json  { render json: {:Exception => "InvalidRequest"}}
				end
				return	
			end
			requests=Array.new
			Request.where(:organization_id => org.id,:answer => -1).each do |r|
				requests << {:username => r.user.email, :orgName => org.title, :orgID=> org.id}
			end
			respond_to do |format|
				format.json  { render json: {:Exception => "null",:requests => requests}}
			end
			return	
		end
		if task == "getAnsweredRequests"
			requests=Array.new
			Request.where(:user_id => user.id).each do |r|
				requests << {:orgName => r.organization.name,:orgID => r.organization.id,:accepted => r.answer==1} unless arr.answer == -1
				r.destroy
			end
		end
		if task == "answerSuggestion"
			sug=Suggestion.find_by_id(params[:sugID])
			unless sug
				respond_to do |format|
					format.json  { render json: {:Exception => "NoIDFound"}}
				end
				return	
			end
			QuestionsUsers.where(:user_id => user.id,:option_num => -1).each do |qu|
				if sug.question==qu.question
					qu.update(:option_num => params[:answer] ? 1 : 2)
					respond_to do |format|
						format.json  { render json: {:Exception => "null"}}
					end
					return	
				end
			end
			respond_to do |format|
				format.json  { render json: {:Exception => "InvalidRequest"}}
			end
			return	
		end
		if task == "answerRequest"
			org=Organization.find_by_id(params[:orgID])
			requester=User.find_by_email(params[:username])
			unless org && requester
				respond_to do |format|
					format.json  { render json: {:Exception => "NoIDFound"}}
				end
				return	
			end
			request=Request.where(:user_id => requester.id,:organization_id => org.id,:answer => -1)[0]
			unless request
				respond_to do |format|
					format.json  { render json: {:Exception => "InvalidRequest"}}
				end
				return	
			end
			request.update(:answer => params[:answer] ? 1 : 2)
			org.users << requester if params[:answer]
			respond_to do |format|
				format.json  { render json: {:Exception => "null"}}
			end
			return	
		end
	end

	private
	def get_suggestion_state(sug)
		q=sug.question
		users=QuestionsUsers.where(:question_id => q.id)
		if users.where(:option_num => 1).size >= (users.size*0.7).ceil
			return "Accepted"
		elsif users.where(:option_num => 2).size >= (users.size*0.7).ceil
			return "Rejected"
		end
		return "InProcess"
	end
	def send_to_users(user,sug)
		quest=Question.new(:content => "")
		quest.suggestion=sug;
		quest.save
		users=Array(sug.organization.users.order("reputation"))#find(:all,:order => "reputation"))
		sum=sug.organization.users.sum(:reputation)-user.reputation
		u_num=((users.size-1)*0.7).ceil
		return if users.size == 1		
		while u_num>0
			r=rand(1..sum)
			my_user=users.each do |u|
				next if u == user
				if u.reputation < r
					r=r-u.reputation
				else
					break u
				end
			end
			sum=sum-my_user.reputation
			u_num=u_num-1
			qu=QuestionsUsers.new
			qu.question=quest
			qu.user=my_user
			qu.option_num=-1
			qu.save
			users.delete(my_user)
		end
	end
	# def r_token
	# 	loop do
	#       	random_token = SecureRandom.urlsafe_base64(nil, false)
	#       	return random_token unless Token.all.find_by_auth_token(random_token)
	# 	end
	# end
end