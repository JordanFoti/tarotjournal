class TarotCard
    attr_accessor :value, :title, :suit, :meaning, :inverted_meaning, :inverted, :id
end

class DateCheck
    attr_accessor :date
    def initialize
        time = Time.new
        self.date = time.strftime("%a %b %d")
    end
end

class Entry
    attr_accessor :date, :log, :id, :image, :tarot, :tarotlog
end
