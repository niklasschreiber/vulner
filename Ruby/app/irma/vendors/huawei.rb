# vim: set fileencoding=utf-8
#
# Author       : G. Cristelli
#
# Creation date: 20151116
#

module Irma
  module Vendor
    definisci_classe_vendor(vendor: VENDOR_HUAWEI) do
      default_formato_audit_of DEFAULT_FORMATO_AUDIT_IDL
      META_ENTITA_RADIO = 'Radio=1'.freeze
      def meta_entita_radio
        META_ENTITA_RADIO
      end

      definisci_classe_rete(rete: RETE_GSM) do
        default_cella_naming_path       'HCGN;BSC;Radio;BTS;GCELL'
        default_formato_audit           DEFAULT_FORMATO_AUDIT_IDL
        default_nodo_naming_path        'HCGN;BSC'
        meta_entita_adiacenza           RETE_GSM  => %w(HCGN;BSC;Radio;GEXT2GCELL),
                                        RETE_UMTS => %w(HCGN;BSC;Radio;GEXT3GCELL),
                                        RETE_LTE  => %w(HCGN;BSC;Radio;GEXTLTECELL)
        meta_entita_relazioni_adiacenza RETE_GSM  => { 'HCGN;BSC;Radio;BTS;GCELL;G2GNCELL' => %w(NBR2GNCELLID) },
                                        RETE_UMTS => { 'HCGN;BSC;Radio;BTS;GCELL;G3GNCELL' => %w(NBR3GNCELLID) },
                                        RETE_LTE  => { 'HCGN;BSC;Radio;BTS;GCELL;GLTENCELL' => %w(NBRLTENCELLID) }
        pr_campi_adiacenza              %w(ADJ UADJ LADJ)
        pr_nome_nodo                    'BSC_NODE_NAME'
        pr_nome_release_nodo            'BSC_REL'

        def estrai_cs_ca_da_relazione(entita) # rubocop:disable Metrics/AbcSize
          # data un' entita di relazione adiacenza, ne estrae la cella sorgente e la cella adiacente
          # per Huawei 2G l'adiacente e' individuabile dal path Radio  con l'aggiunta dell'entita di adiacenza valorizzata con il valore
          # del parametro NBRxxCELLID della relazione di adiacenza: memorizziamo solo il valore del parametro NBR
          # mentre per la cella sorgente mettiamo il path dell'oggetto cella
          rete = get_rete_from_meta_entita_rel_adj(entita.naming_path)
          cella_adiacente = entita.parametri[meta_entita_relazioni_adiacenza[rete][entita.naming_path][0]]
          cella_sorgente = entita.dist_name[0, entita.dist_name.index(DIST_NAME_SEP, entita.dist_name.index(meta_entita_cella(RETE_GSM)))]
          [cella_sorgente, cella_adiacente]
        end
      end

      definisci_classe_rete(rete: RETE_UMTS) do
        default_cella_naming_path             'HCGN;RAN;Radio;UNODEB;UCELL'
        default_formato_audit                 DEFAULT_FORMATO_AUDIT_IDL
        default_nodo_naming_path              'HCGN;RAN'
        meta_entita_adiacenza                 RETE_GSM  => %w(HCGN;RAN;Radio;UEXT2GCELL),
                                              RETE_UMTS => %w(HCGN;RAN;Radio;UNRNC;UEXT3GCELL),
                                              RETE_LTE  => %w(HCGN;RAN;Radio;ULTECELL)
        meta_entita_relazioni_adiacenza_inter 'HCGN;RAN;Radio;UNODEB;UCELL;UINTERFREQNCELL' => %w(NCELLID NCELLRNCID)
        meta_entita_relazioni_adiacenza_intra 'HCGN;RAN;Radio;UNODEB;UCELL;UINTRAFREQNCELL' => %w(NCELLID NCELLRNCID)
        meta_entita_relazioni_adiacenza       RETE_GSM  => { 'HCGN;RAN;Radio;UNODEB;UCELL;U2GNCELL' => %w(GSMCELLINDEX) },
                                              RETE_UMTS => meta_entita_relazioni_adiacenza_intra.merge(meta_entita_relazioni_adiacenza_inter),
                                              RETE_LTE  => { 'HCGN;RAN;Radio;UNODEB;UCELL;ULTENCELL' => %w(LTECELLINDEX) }
        pr_campi_adiacenza                    %w(ADJI ADJS GADJ LADJ)
        pr_campi_per_controlli                %w(NODEBID)
        pr_nome_nodo                          'RNC_NODE_NAME'
        pr_nome_release_nodo                  'RNC_REL'

        def self.comportamento_nessun_padre(_v = nil)
          @comportamento_nessun_padre ||= begin
                                            v = Marshal.load(Marshal.dump(super))
                                            ece = EsitoCalcoloEntita.new(azione: AZIONE_CALCOLO_ENTITA_SKIP)
                                            v[FASE_CALCOLO_ADJ] = ece
                                            v
                                          end
        end

        def estrai_cs_ca_da_relazione(entita) # rubocop:disable Metrics/AbcSize
          # data un' entita di relazione adiacenza, ne estrae la cella sorgente e la cella adiacente
          # per Huawei 3G, l'identificativo della cella adiacente e' una concatenazione di parametri
          # in cui puo' esserci o meno il parametro LOGICALCELLID a seconda della lunghezza del nome RNC_REL
          # Poiche'non conosco RNC_REL, metto solamente i valori dei parametri che mi consentono il match con l'adiacente:
          # U2L: il parametro LTECELLINDEX della relazione corrisponde al parametro LTECELLINDEX della adiacente
          # U2G: il parametro GSMCELLINDEX della relazione corrisponde al parametro GSMCELLINDEX della adiacente
          # U2U: verso adiacente interna: i parametri NCELLID NCELLRNCID della relazione corrispondo rispettivamente al parametro CELLID della adiacente e al parametro RNCID dell'oggetto RAN...
          # U2U: verso adiacente esterna: i parametri NCELLID NCELLRNCID della relazione corrispondo rispettivamente ai parametri CELLID e NRNCID dell'oggetto UEXT3GCELL
          rete = get_rete_from_meta_entita_rel_adj(entita.naming_path)
          cella_adiacente = meta_entita_relazioni_adiacenza[rete][entita.naming_path].map { |p| entita.parametri[p] }.compact.join('+')
          cella_sorgente = entita.dist_name[0, entita.dist_name.index(DIST_NAME_SEP, entita.dist_name.index(meta_entita_cella(RETE_UMTS)))]
          [cella_sorgente, cella_adiacente]
        end
      end

      definisci_classe_rete(rete: RETE_LTE) do
        default_cella_naming_path             'HCGN;ENODEB;ENODEB;RADIO;CELL'
        default_formato_audit                 DEFAULT_FORMATO_AUDIT_IDL
        default_nodo_naming_path              'HCGN;ENODEB'
        meta_entita_adiacenza                 RETE_GSM  => %w(HCGN;ENODEB;ENODEB;RADIO;GERANEXTERNALCELL),
                                              RETE_UMTS => %w(HCGN;ENODEB;ENODEB;RADIO;UTRANEXTERNALCELL),
                                              RETE_LTE  => %w(HCGN;ENODEB;ENODEB;RADIO;EUTRANEXTERNALCELL)
        meta_entita_relazioni_adiacenza_inter 'HCGN;ENODEB;ENODEB;RADIO;CELL;EUTRANINTERFREQNCELL' => %w(NEIGHBOURCELLNAME CELLID ENODEBID MCC MNC)
        meta_entita_relazioni_adiacenza_intra 'HCGN;ENODEB;ENODEB;RADIO;CELL;EUTRANINTRAFREQNCELL' => %w(NEIGHBOURCELLNAME CELLID ENODEBID MCC MNC)
        meta_entita_relazioni_adiacenza       RETE_GSM  => { 'HCGN;ENODEB;ENODEB;RADIO;CELL;GERANNCELL' => %w(GERANCELLID LAC MCC MNC) },
                                              RETE_UMTS => { 'HCGN;ENODEB;ENODEB;RADIO;CELL;UTRANNCELL' => %w(MCC MNC CELLID RNCID) },
                                              RETE_LTE  => meta_entita_relazioni_adiacenza_intra.merge(meta_entita_relazioni_adiacenza_inter)
        pr_campi_adiacenza                    %w(ADJI ADJS UADJ GADJ)
        pr_campi_per_controlli                %w(EARFCNDL)
        pr_nome_id_nodo                       'ENODEBID'
        pr_nome_nodo                          'E_NODEB_NAME'
        pr_nome_release_nodo                  'ENODEB_REL'

        def estrai_cs_ca_da_relazione(entita) # rubocop:disable Metrics/AbcSize
          # data un' entita di relazione adiacenza, ne estrae la cella sorgente e la cella adiacente
          # per Huawei 4G il nome dell'adiacente esterna corrisponte alla concatenazione di un elenco di parametri
          # in particolare, per le L2L, il parametro NEIGHBOURCELLNAME esiste solo per le interne ed e' l'unico modo per trovare poi la relazione con la cella
          # mentre per la cella sorgente mettiamo il path dell'oggetto cella
          rete = get_rete_from_meta_entita_rel_adj(entita.naming_path)
          cella_a = meta_entita_relazioni_adiacenza[rete][entita.naming_path].map { |p| entita.parametri[p] if entita.parametri[p] }.compact.join('+')
          cella_s = entita.dist_name[0, entita.dist_name.index(DIST_NAME_SEP, entita.dist_name.index(meta_entita_cella(RETE_LTE)))]
          [cella_s, cella_a.chomp('+')]
        end
      end
    end
  end
end
