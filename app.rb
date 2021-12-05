require 'sinatra'
require 'my_app'
require 'models'
require 'rubygems'
require 'rmagick'
require 'sinatra/base'
enable :sessions
include FileUtils::Verbose
tarot= TarotDeck.new
store= JournalStore.new

    get('/tarot/:count') do
        time= Time.new
        @datecheck= DateCheck.new
        @entry= Entry.new
        @tarotdeck= tarot.all
        @tarotdeck.pop
        @tarotdeck= @tarotdeck.shuffle
        @entry.date= time.strftime("%A, %B %d %Y - %I:%M%p")
        store.getid(@entry)
        @entry.tarot=[]
        @entry.tarotlog= []
        deals= params['count'].to_i
        @deal=[]
        deals.times{@deal<<@tarotdeck.pop}
        @deal.each do |dealt|
            dealt.inverted= dorandom
            if dealt.inverted== "Inverted"
                @entry.tarotlog+= ["<div class='tooltip'>#{dealt.title} Inverted<span class='tooltiptext'>#{dealt.inverted_meaning}</span></div>"]
                tarot.invert(dealt.id, dealt.inverted)
            else
                @entry.tarotlog+= ["<div class='tooltip'>#{dealt.title}<span class='tooltiptext'>#{dealt.meaning}</span></div>"]
            end
            @entry.tarot+= ["#{dealt.id}#{dealt.inverted}"]
        end
        store.save(@entry)    
        @datecheck.date = time.strftime("%a %b %d")
        tarot.save(@datecheck)
        erb :tarot, :layout => :tarotbg
    end

    get('/choose') do
        @datecheck= DateCheck.new
        @datecheck= tarot.check
        time= Time.new
        if @datecheck.date == time.strftime("%a %b %d")
            @journal= store.all
            erb :index
        else
            erb :choose, :layout => :tarotbg
        end
    end


    get '/images/:file' do
        send_file('public/images/uploaded/'+params[:file], :disposition => 'inline')
    end

    get('/view/:id,:ref') do
        id= params['id'].to_i
        ref= params['ref'].to_i
        @tarotcard= tarot.find(id)
        @id= ref
        erb :view, :layout => :post
    end


    def dorandom
        x= rand(2)
        if x==1
            dorandom= "Inverted"
        else 
            dorandom=  nil
        end
    end

    get('/journal') do
        @journal= store.all
        erb :index
    end

    get('/') do
        @journal= store.all
        erb :index
    end


    get('/journal/new') do
        erb :new
    end

    get ('/edit/:id') do
        id= params['id'].to_i
        @entry= Entry.new
        @entry= store.find(id)
        erb :edit
    end

    get('/refresh') do
        @id= session.delete(:id)
        erb :refresh
    end

    get('/journal/:id') do
        id= params['id'].to_i
        @entry= store.find(id)
        erb :show
    end

    post('/edit/:id') do
        @entry= Entry.new
        id= params['id'].to_i
        @entry= store.find(id)
        if params[:file]
            filename= params[:file][:filename]
            tempfile= params[:file][:tempfile]
            cp(tempfile.path, "public/images/uploaded/#{filename}")
            @entry.image= "#{filename}"
            img = Magick::Image::read("public/images/uploaded/#{filename}")[0]
            if img.columns < img.rows && img.columns > 600
                img.resize(600,800).write("public/images/uploaded/#{filename}")
            elsif img.columns > img.rows && img.rows > 600
                img.resize(800,600).write("public/images/uploaded/#{filename}")
            else
            end
        end
        @checkvideo= params['log']
        if @checkvideo.include?("/watch?v=")
            embed= get_youtube_id(@checkvideo)
            @entry.log= "<object data='https://www.youtube.com/embed/#{embed}' width='800px' height='600px'></object>"
        else
            @entry.log= @checkvideo
        end
        store.save(@entry)
        session[:id] = @entry.id
        redirect '/refresh'
    end

    delete('/journal/:id') do
        id= params['id'].to_i
        store.delete(id)
        redirect '/journal'
    end

    post('/upload') do
        @entry= Entry.new
        if params[:file]
            filename= params[:file][:filename]
            tempfile= params[:file][:tempfile]
            cp(tempfile.path, "public/images/uploaded/#{filename}")
            @entry.image= "#{filename}"
            img = Magick::Image::read("public/images/uploaded/#{filename}")[0]
            if img.columns < img.rows && img.columns > 600
                img.resize(600,800).write("public/images/uploaded/#{filename}")
            elsif img.columns > img.rows && img.rows > 600
                img.resize(800,600).write("public/images/uploaded/#{filename}")
            else
            end
        end
        time= Time.new
        @entry.date= time.strftime("%A, %B %d %Y - %I:%M%p")
        @checkvideo= params['log']
        if @checkvideo.include?("/watch?v=")
            embed= get_youtube_id(@checkvideo)
            @entry.log= "<object data='https://www.youtube.com/embed/#{embed}' width='800px' height='600px'></object>"
        else
            @entry.log= @checkvideo
        end
        store.save(@entry)
        redirect '/refresh'
    end

    post('/tarot/comment/:id') do
        @entry= Entry.new
        id= params['id'].to_i
        @entry= store.find(id)
        @entry.log= params['log']
        store.save(@entry)
        redirect "/journal##{@entry.id}"
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
