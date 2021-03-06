module Policr::Model
  class BlockRule < Jennifer::Model::Base
    with_timestamps

    mapping(
      id: Primary32,
      chat_id: Int64,
      version: String,
      alias_s: String,
      expression: String,
      enabled: Bool,
      in_message: Bool,
      in_nickname: Bool,
      created_at: Time?,
      updated_at: Time?
    )

    def self.enabled?(chat_id : Int64)
      where { (_chat_id == chat_id) & (_enabled == true) }.count > 0
    end

    def self.disable_all(chat_id : Int64)
      where { (_chat_id == chat_id) & (_enabled == true) }.update { {:enabled => false} }
    end

    def self.update!(id : Int32 | Nil, expression : String, alias_s : String)
      if bc = find id
        bc.update_columns({
          :expression => expression,
          :alias_s    => alias_s,
        })
        bc
      else
        raise Exception.new "Not Found"
      end
    end

    def self.add!(chat_id : Int64, expression : String, alias_s : String)
      create!({
        chat_id:     chat_id,
        version:     "v2",
        alias_s:     alias_s,
        expression:  expression,
        enabled:     false,
        in_message:  true,
        in_nickname: false,
      })
    end

    macro def_apply(name, column)
      def self.apply_{{name.id}}!(id : Int32 | Nil)
        if br = find id
          br.update_column {{column}}, true
        else
          raise Exception.new "Not Found"
        end
      end

      def self.disapply_{{name.id}}(id : Int32 | Nil)
        if br = find id
          br.update_column {{column}}, false
        end
      end
    end

    def_apply "message", :in_message
    def_apply "nickname", :in_nickname

    macro def_apply_list(name, column)
      def self.apply_{{name.id}}_list(chat_id : Int64)
        where { 
          (_chat_id == chat_id) & 
          (_enabled == true) &
          (_{{column.id}} == true)
        }.offset(0).limit(5).to_a
      end
    end

    def_apply_list "message", :in_message
    def_apply_list "nickname", :in_nickname

    def self.enable!(id : Int32 | Nil)
      if br = find id
        br.update_column :enabled, true
      else
        raise Exception.new "Not Found"
      end
    end

    def self.disable(id : Int32 | Nil)
      if br = find id
        br.update_column :enabled, false
      end
    end

    def self.all_list(chat_id : Int64)
      where { _chat_id == chat_id }.offset(0).limit(5).to_a
    end

    def self.counts(chat_id : Int64) : Int
      where { _chat_id == chat_id }.count
    end
  end
end
