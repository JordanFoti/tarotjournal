require 'sinatra'
require 'rubygems'
require 'rmagick'
require 'models'
require 'my_app'
enable :sessions
include FileUtils::Verbose
tarot = TarotDeck.new
store = JournalStore.new

get('/tarot') do
    lockout = tarot.check
    time = Time.new
    redirect '/' if lockout.date == time.strftime("%a %b %d")
    datecheck = DateCheck.new
    @entry = Entry.new
    tarotdeck = tarot.all
    tarotdeck.pop
    tarotdeck = tarotdeck.shuffle
    @entry.date = time.strftime("%A, %B %d %Y - %I:%M%p")
    store.getid(@entry)
    @entry.tarot = []
    @entry.tarotlog = []
    tarotdeck.each do |dealt|
        if rand(2) == 1 
            dealt.inverted = "Inverted"
            @entry.tarotlog += ["<div class='tooltip'>#{dealt.title} Inverted<span class='tooltiptext'>#{dealt.inverted_meaning}</span></div>"]
            tarot.invert(dealt.id, dealt.inverted)
        else
            dealt.inverted = nil
            @entry.tarotlog += ["<div class='tooltip'>#{dealt.title}<span class='tooltiptext'>#{dealt.meaning}</span></div>"]
            tarot.invert(dealt.id, dealt.inverted)
        end
        @entry.tarot += ["#{dealt.id}#{dealt.inverted}"]
    end
    store.save(@entry)
    session.delete(:chosen)
    erb :tarot, :layout => :tarotbg
end

get('/tarot/:ref,:id') do
    entry = params['ref'].to_i
    id = params['id'].to_i
    @entry = store.find(entry)
    if session[:chosen] 
        session[:chosen] += [@entry.tarot.slice(id)]
        session[:log] += [@entry.tarotlog.slice(id)]
    else
        session[:chosen] = []
        session[:log] = []
        session[:chosen] += [@entry.tarot.slice(id)]
        session[:log] += [@entry.tarotlog.slice(id)]
    end
    @chosen = session.delete(:chosen)
    @log = session.delete(:log)
    if @chosen.count == session[:cards]
        datecheck = DateCheck.new
        @entry.tarot = @chosen
        @entry.tarotlog = @log
        store.save(@entry)
        tarot.save(datecheck)
        session[:id]= @entry.id
        redirect 'tarot/thoughts'
    end
    @entry.tarot.delete_at(id)
    @entry.tarotlog.delete_at(id)
    store.save(@entry)
    session[:chosen] = @chosen
    session[:log] = @log
    erb :tarot2, :layout => :tarotbg
end

get '/tarot/thoughts' do
    @id = session.delete(:id)
    @entry= store.find(@id)
    erb :tarot3, :layout => :tarotbg
end

get('/choose') do
    lockout = tarot.check
    time = Time.new
    redirect '/' if lockout.date == time.strftime("%a %b %d")
    erb :choose, :layout => :tarotbg
end

get('/choose/:id') do
    id = params['id'].to_i
    session[:cards] = id
    redirect '/tarot'    
    end


get '/images/:file' do
    send_file('public/images/uploaded/'+params[:file], :disposition => 'inline')
end

get('/view/:id,:ref') do
    id = params['id'].to_i
    ref = params['ref'].to_i
    @tarotcard = tarot.find(id)
    @id = ref
    erb :view, :layout => :border
end

get('/') do
    @journal = store.all
    erb :index do
        erb :entry
    end
end


get('/journal/new') do
    erb :new
end

get ('/edit/:id') do
    id = params['id'].to_i
    @entry = store.find(id)
    erb :edit
end

get('/refresh') do
    @id = session.delete(:id)
    erb :refresh
end

get('/journal/:id') do
    id = params['id'].to_i
    @entry = store.find(id)
    erb :show do
        erb :entry
    end
end

post('/edit/:id') do
    id = params['id'].to_i
    @entry = store.find(id)
    session[:id]= id
    checkparams
    store.save(@entry)
    redirect '/refresh'
end

post('/upload') do
    @entry = Entry.new
    time = Time.new
    @entry.date = time.strftime("%A, %B %d %Y - %I:%M%p")
    checkparams
    store.save(@entry)
    redirect '/refresh'
end

post('/tarot/comment/:id') do
    id = params['id'].to_i
    @entry = store.find(id)
    @entry.log = params['log']
    store.save(@entry)
    redirect "/##{@entry.id}"
end

delete('/journal/:id') do
    id = params['id'].to_i
    store.delete(id)
    redirect '/'
end

def get_youtube_id(url)
    id = ''
    url = url.gsub(/(>|<)/i,'').split(/(vi\/|v=|\/v\/|youtu\.be\/|\/embed\/)/)
    if url[2] != nil
        id = url[2].split(/[^0-9a-z_\-]/i)
        id = id[0];
    else
        id = url;
    end
    id
end

def checkparams
    if params[:file]
        filename = params[:file][:filename]
        tempfile = params[:file][:tempfile]
        cp(tempfile.path, "public/images/uploaded/#{filename}")
        @entry.image = "#{filename}"
        img = Magick::Image::read("public/images/uploaded/#{filename}")[0]
        if img.columns < img.rows && img.columns > 600
            img.resize(600,800).write("public/images/uploaded/#{filename}")
        elsif img.columns > img.rows && img.rows > 600
            img.resize(800,600).write("public/images/uploaded/#{filename}")
        else
        end
    end
    if params['log'].include?("/watch?v=")
        embed = get_youtube_id(params['log'])
        @entry.log = "<object data='https://www.youtube.com/embed/#{embed}' width='800px' height='600px'></object>"
    else
        @entry.log = params['log']
    end
end