# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151123
#

module Irma
  module Db
    #
    class Evento < Model(:eventi)
      plugin :timestamps, update_on_create: true

      # many_to_one  :tipo_evento, class: TipoEvento

      # do not allow update (a trigger in the db should be created too)
      def before_update
        raise 'Aggiornamento evento non consentito per policy di sicurezza'
      end

      validates_constant :gravita

      configure_retention 90, min: 7, max: 365

      def self.pubblica_sulla_coda(coda, opts = {})
        super(coda, opts.reject { |k, _v| %i(dettaglio).include?(k) })
      end

      def self.crea(tipo_evento, opts = {})
        tipo_evento = TipoEvento.get_by_pk(tipo_evento) unless tipo_evento.is_a?(TipoEvento)
        e = create({
          categoria:      tipo_evento.categoria,
          nome:           tipo_evento.nome,
          gravita:        tipo_evento.gravita,
          tipo_evento_id: tipo_evento.id
        }.merge(opts))
        logger.info("Creato un nuovo evento \"#{e.categoria}:#{e.nome}\": #{e.attributes.inspect}")
        e
      end

      def initialize(*args)
        super
        self.host ||= Irma.host_ip
      end
    end
  end
end

# == Schema Information
#
# Tabella: eventi
#
#  account_id     :integer
#  ambiente       :string(10)
#  attivita_id    :bigint
#  categoria      :string(64)      non nullo
#  created_at     :datetime
#  descr          :string
#  dettaglio      :json
#  durata         :integer
#  gravita        :integer         non nullo
#  host           :string(32)
#  id             :bigint          non nullo, default(nextval('eventi_id_seq')), chiave primaria
#  id_allarme     :integer
#  matricola      :string(16)
#  nome           :string(64)      non nullo
#  pid            :bigint
#  profilo        :string(32)
#  tipo_evento_id :integer         non nullo, riferimento a tipi_eventi.id
#  updated_at     :datetime
#  utente_descr   :string(64)
#
# Indici:
#
#  idx_eventi_id_allarme      (id_allarme)
#  idx_eventi_nome_categoria  (categoria,nome)
#
