require 'yaml/store'

class JournalStore
    def initialize
        @store= YAML::Store.new("journal.yml")
    end

    def find(id)
        @store.transaction do
            @store[id]
        end
    end

    def save(entry)
        @store.transaction do
            unless entry.id
                highest_id= @store.roots.max || 0
                entry.id= highest_id+ 1
            end
            @store[entry.id]= entry
        end
    end

    def getid(entry)
        @store.transaction do
            highest_id= @store.roots.max || 0
            entry.id= highest_id+ 1
            @store[entry.id]= entry
        end
    end


    def all
        @store.transaction do
            @store.roots.map {|id| @store[id]}
        end
    end

    def delete(entry)
        @store.transaction do
            @store.delete(entry)
        end
    end

end

class TarotDeck
    def initialize
        @store= YAML::Store.new("deck.yml")
    end

    def find(id)
        @store.transaction do
            @store[id]
        end
    end

    def all
        @store.transaction do
            @store.roots.map {|id| @store[id]}
        end
    end

    def invert(id, string)
        @store.transaction do
            @store[id].inverted= string
        end
    end

    def save(datecheck)
        @store.transaction do
            @store[79]= datecheck
        end
    end

    def check
        @store.transaction do
            @store[79]
        end
    end
end

