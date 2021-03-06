angular.module 'mnoEnterpriseAngular'
  .controller 'OnboardingStep3Controller', (MnoeOrganizations, MnoeAppInstances) ->
    'ngInject'

    vm = this

    vm.isFetchingAppInstances = true

    MnoeAppInstances.getAppInstances().then(
      (response) ->
        vm.appInstances = angular.copy(response)
        vm.nbApps = _.size(vm.appInstances)
        vm.nbAppsToConnect = _.size(_.filter(vm.appInstances, (ai) -> MnoeAppInstances.installStatus(ai) == "INSTALLED_CONNECT"))
    ).finally(-> vm.isFetchingAppInstances = false)

    return
