# vim: set fileencoding=utf-8
#
# Author: G. Cristelli
#
# Creation date: 20090825
#

module Irma
  module Db
    #
    class Utente < Model(:utenti)
      plugin :timestamps, update_on_create: true
      one_to_many :accounts, class: full_class_for_model(:Account)

      # plugin :association_dependencies
      # add_association_dependencies accounts: :destroy # :nullify ...

      def self.cache_enabled?
        !@cache_disabled
      end

      def before_create
        self.matricola = matricola.upcase
      end

      # Ritorna le informazioni presenti sull'ldap come un hash di opzioni valide come attributi
      # Se si verifica un problema viene generata un'eccezione (vedi Ds_ti.getUserInfo)
      def self.ldap_info(matricola)
        options = {}
        user_info = Ds_ti.get_user_info(matricola, %w(cn givenName sn department mail mobile))
        if user_info
          options = {
            'nome' => user_info['givenName'], 'cognome' => user_info['sn'], 'dipartimento' => user_info['department'],
            'email' => user_info['mail'], 'mobile' => user_info['mobile']
          }
        end
        options
      end

      def fullname
        nome.to_s + ' ' + cognome.to_s
      end

      def formato_per_gui
        @formato_per_gui ||= Irma.descrizione_utente_per_gui(matricola: matricola, fullname: fullname)
      end

      def self.find_by_matricola(matricola)
        first(matricola: matricola.to_s.downcase)
      end

      def chiudi_allarmi_aperti(note_chiusura = 'Utente eliminato dal DB')
        Allarme.all(user_name: matricola).each { |al| al.chiudi(note_chiusura) }
      end
    end
  end
end

# == Schema Information
#
# Tabella: utenti
#
#  cognome      :string(64)      non nullo
#  created_at   :datetime
#  dipartimento :string
#  email        :string
#  id           :integer         non nullo, default(nextval('utenti_id_seq')), chiave primaria
#  matricola    :string(64)      non nullo
#  mobile       :string
#  nome         :string(64)      non nullo
#  updated_at   :datetime
#
# Indici:
#
#  uidx_utenti_matricola  (matricola) UNIQUE
#
