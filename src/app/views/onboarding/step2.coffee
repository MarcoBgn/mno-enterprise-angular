angular.module 'mnoEnterpriseAngular'
  .controller 'OnboardingStep2Controller', ($q, $state, $uibModal, MnoeMarketplace, MnoeOrganizations, MnoeAppInstances) ->
    'ngInject'

    vm = this

    MAX_APPS_ONBOARDING = 4

    vm.searchTerm = ''
    vm.isLoading = true

    vm.selectedApps = []

    vm.appsFilter = (app) ->
      if (vm.searchTerm? && vm.searchTerm.length > 0) || !vm.selectedCategory
        return true
      else
        return _.contains(app.categories, vm.selectedCategory)

    # Select or deselect an app
    vm.toggleApp = (app) ->
      # User cannot add more apps
      return if vm.maxAppsSelected && !app.checked
      app.checked = !app.checked
      if app.checked
        vm.selectedApps.push(app)
      else
        _.remove(vm.selectedApps, app)
      vm.maxAppsSelected = (vm.selectedApps.length == MAX_APPS_ONBOARDING)
      return

    # ====================================
    # Connect the apps & go to next screen
    # ====================================
    vm.connectApps = () ->
      vm.isConnectingApps = true
      # List of app instances to add and delete
      appsToAdd = _.filter(vm.marketplace.apps, (app) -> app.checked == true && not _.contains(vm.originalAppNids, app.nid))
      appsToDelete = _.filter(vm.marketplace.apps, (app) -> app.checked == false && _.contains(vm.originalAppNids, app.nid))
      # Purchase new apps
      promises = _.map(appsToAdd, (app) -> MnoeOrganizations.purchaseApp(app))
      # Terminate old apps
      promises = _(promises).concat(_.map(appsToDelete, (app) -> MnoeAppInstances.terminate(app.id))).value()
      # Refresh app instances and go to next screen
      $q.all(promises).finally(
        ->
          MnoeAppInstances.refreshAppInstances().then(
            ->
              vm.isConnectingApps = false
              $state.go('onboarding.step3')
          )
      )

    # ====================================
    # App Info modal
    # ====================================
    vm.openInfoModal = (app) ->
      $uibModal.open(
        templateUrl: 'app/views/onboarding/modals/app-infos.html'
        controller: 'MnoAppInfosCtrl'
        controllerAs: 'vm',
        size: 'lg'
        resolve:
          app: app
      )

    $q.all({
      appInstances: MnoeAppInstances.getAppInstances()
      marketplace: MnoeMarketplace.getApps()
    }).then(
      (response) ->
        vm.appInstances = response.appInstances
        vm.marketplace = response.marketplace.plain()

        # Fetch the already selected apps
        vm.originalAppNids = _.map(vm.appInstances, 'app_nid')

        # Toggle the already selected apps
        _.each(_.filter(vm.marketplace.apps, (app) -> _.contains(vm.originalAppNids, app.nid)), (a) -> vm.toggleApp(a))
    ).finally(-> vm.isLoading = false)

    return
