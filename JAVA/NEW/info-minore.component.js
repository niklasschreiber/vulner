angular.module('app').component('infoMinore', {
    templateUrl: '/buoni-emissioni-associazione-ruoli/ui/app/v1/js/components/buono-minore/info-minore/info-minore.template.html',
    bindings: {
        minore: '<',
        productId: '@',
        onMinoreInfo: '&'
    },
    controllerAs: '$infoMinore',
    controller: 'infoMinoreController'
}).controller('infoMinoreController', ['bminAssociazioneRuoliService', 'modalConfigFactory', 'BMIN_ERROR_MESSAGES', '$timeout',function(bminAssociazioneRuoliService, modalConfigFactory, BMIN_ERROR_MESSAGES, $timeout){
    var vm = this;

    vm.fiscalId = "";
    vm.name = "";
    vm.surname = "";
    vm.reportNumber = "";
    vm.infoArrived = false;

    vm.$onInit = function() {
        if(vm.minore) {
            // recupero sessione, mostro direttamente i dati
            vm.infoArrived = true;
            vm.fiscalId = vm.minore.fiscalId;
            vm.name = vm.minore.name;
            vm.surname = vm.minore.surname;
            vm.reportNumber = vm.minore.reportNumber;
        }
    }

    vm.findMinoreInfo = function(cf) {
        if(!cf) {
            showModalError(BMIN_ERROR_MESSAGES.getErrorMessage("GENERIC_NO_INFO"));
            angular.element('#cfMinore').addClass('erroreCf');
        } else if(!vm.controlloCf(cf)) {
            showModalError(BMIN_ERROR_MESSAGES.getErrorMessage("NOT_VALID_CF"));
            angular.element('#cfMinore').addClass('erroreCf');
        } else if(!checkMinore(cf)) {
            showModalError(BMIN_ERROR_MESSAGES.getErrorMessage("CF_NOT_MINORE"))
        } else {
            bminAssociazioneRuoliService.retrieveInfoMinore(cf, vm.productId).then(function(response){
                vm.infoArrived = true;
                vm.fiscalId = response.infoMinore.minore.codiceFiscale;
                vm.name = response.infoMinore.minore.nome;
                vm.surname = response.infoMinore.minore.cognome;
                vm.reportNumber = response.infoMinore.reportNumber;
                vm.onMinoreInfo({data: response});
            }).catch(function(err) {
                showModalError(err.description);
            });
        }
    }

    vm.controlloCf = function(cf) {
        return bminAssociazioneRuoliService.checkCodiceFiscale(cf);
    }

    function showModalError(msg) {
        var isYellow = true;
        var nonDismissable = false;
        var modalBtn = modalConfigFactory.getButton("Chiudi", hideModal, isYellow);
        var modalConfig = modalConfigFactory.getConfig("Attenzione", msg, nonDismissable, [modalBtn], hideModal);
        openModal(modalConfig);
    }

    function openModal(modalConfig) {
        vm.modalConfig = modalConfig;
        $timeout(function () {
            vm.showModal = {value: true};
        })
    }

    function hideModal() {
        vm.showModal = {value: false};
        
        $timeout(function () {
            vm.modalConfig = undefined;
        });
    }

    function dataCf (codiceFiscale) {
        var MESI = { A: '01', B: '02', C: '03', D: '04', E: '05', H: '06', L: '07', M: '08', P: '09', R: '10', S: '11', T: '12' };
        var anno = codiceFiscale.substring(6,8), 
            giorno = codiceFiscale.substring(9,11);
        if (giorno>40) {
            giorno -= 40;
            giorno = "0" + giorno;
        }
        return {
            anno: anno,
            mese: MESI[codiceFiscale.charAt(8)],
            giorno: giorno
        }
    }

    function checkMinore(cf) {
        var minore = false;
        var oggi = (new Date().getFullYear() + "").substring(2);
        var data = dataCf(cf);
        var anno = data.anno;
        var mese = data.mese;
        var giorno = data.giorno;

            if (parseInt(anno) <= parseInt(oggi)) {

                minore = parseInt(anno) > (parseInt(oggi)- 18) ? true : false;

                if (parseInt(anno) == (parseInt(oggi) - 18)) {
                    var meseOggi = new Date().getMonth() + 1;
                    minore = parseInt(mese) > parseInt(meseOggi) ? true : false;

                    if (parseInt(meseOggi) == parseInt(mese)) {
                        var giornoOggi = new Date().getDate();
                        minore = parseInt(giorno) >= parseInt(giornoOggi) ? true : false;
                    }
                }
            }
        return minore;
    }
}])