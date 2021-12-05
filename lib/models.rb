class TarotCard
    attr_accessor :value, :title, :suit, :meaning, :inverted_meaning, :inverted, :id
end

class DateCheck
    attr_accessor :date
end

class Entry
    attr_accessor :date, :log, :id, :image, :tarot, :tarotlog
end
