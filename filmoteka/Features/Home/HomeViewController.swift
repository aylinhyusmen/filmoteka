import UIKit

final class HomeViewController: UIViewController {
    
    @IBOutlet weak var homeFeedTable: UITableView!

    private enum Constants {
        static let upcomingCellID = "UpcomingCell"
        static let categoryCellID = "CategoryCell"
        static let searchCellID = "SearchCell"
        static let headerHeight: CGFloat = 450
        static let rowHeight: CGFloat = 280
        static let searchRowHeight: CGFloat = 50
    }

    let searchController = UISearchController(searchResultsController: nil)
    let modeControl = UISegmentedControl(items: ["Movies", "TV Shows"])

    let viewModel = HomeViewModel()

    var isSearching: Bool {
        searchController.isActive && !(searchController.searchBar.text ?? "").isEmpty
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSearch()
        setupNavigationBar()
        homeFeedTable.register(UITableViewCell.self, forCellReuseIdentifier: Constants.searchCellID)
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.fetchDataIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.cancelFeed()
    }

    private func bindViewModel() {
        viewModel.onFeedUpdated = { [weak self] in
            self?.homeFeedTable.reloadData()
        }
        viewModel.onSearchUpdated = { [weak self] in
            self?.homeFeedTable.reloadData()
        }
        viewModel.onError = { [weak self] error in
            self?.showError(error)
        }
    }

    private func setupUI() {
        view.backgroundColor = UIColor(named: "DeepDark")
        navigationController?.navigationBar.barTintColor = UIColor(named: "DeepDark")
        navigationController?.navigationBar.isTranslucent = true

        modeControl.selectedSegmentIndex = 0
        modeControl.selectedSegmentTintColor = .systemRed
        modeControl.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: UIFont.boldSystemFont(ofSize: 14)], for: .selected)
        modeControl.setTitleTextAttributes([.foregroundColor: UIColor.lightGray], for: .normal)
        modeControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
    }

    private func setupNavigationBar() {
        modeControl.sizeToFit()
        let titleWrapper = UIView(frame: modeControl.bounds)
        titleWrapper.addSubview(modeControl)
        navigationItem.titleView = titleWrapper
        navigationItem.searchController = searchController
        definesPresentationContext = true
        navigationController?.navigationBar.tintColor = .white

        let profileButton = UIBarButtonItem(
            image: UIImage(systemName: "person.crop.circle"),
            style: .plain,
            target: self,
            action: #selector(profileTapped)
        )
        navigationItem.rightBarButtonItem = profileButton
    }

    private func setupSearch() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.applyFilmTheme()
    }

    @objc private func segmentChanged() {
        guard let newMode = HomeViewModel.FeedMode(rawValue: modeControl.selectedSegmentIndex) else { return }
        viewModel.currentMode = newMode
        homeFeedTable.setContentOffset(.zero, animated: true)
    }

    @objc private func profileTapped() {
        if viewModel.isUserLogged {
            Navigator.shared.navigateToProfile(from: navigationController)
        } else {
            Navigator.shared.navigateToLogin(from: navigationController)
        }
    }
}

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        isSearching ? viewModel.searchResults.count : viewModel.categories.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isSearching { return configureSearchCell(for: tableView, at: indexPath) }
        return indexPath.row == 0
            ? configureUpcomingCell(for: tableView, at: indexPath)
            : configureCategoryCell(for: tableView, at: indexPath)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if isSearching { return Constants.searchRowHeight }
        return indexPath.row == 0 ? Constants.headerHeight : Constants.rowHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard isSearching, indexPath.row < viewModel.searchResults.count else { return }
        let movie = viewModel.searchResults[indexPath.row]
        Navigator.shared.navigateToMovieDetail(with: movie, from: navigationController)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    private func configureSearchCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.searchCellID)
            ?? UITableViewCell(style: .default, reuseIdentifier: Constants.searchCellID)

        guard indexPath.row < viewModel.searchResults.count else { return cell }
        let movie = viewModel.searchResults[indexPath.row]

        cell.backgroundColor = .black
        var content = cell.defaultContentConfiguration()
        content.text = movie.displayTitle
        content.textProperties.color = .white
        content.textProperties.font = .systemFont(ofSize: 16, weight: .semibold)
        cell.contentConfiguration = content

        let selectionView = UIView()
        selectionView.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
        cell.selectedBackgroundView = selectionView

        return cell
    }

    private func configureUpcomingCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Constants.upcomingCellID, for: indexPath) as? UpcomingTableViewCell else {
            return UITableViewCell()
        }

        cell.configure(with: viewModel.upcomingMedia)
        cell.didTapMovie = { [weak self] movie in
            Navigator.shared.navigateToMovieDetail(with: movie, from: self?.navigationController)
        }
        return cell
    }

    private func configureCategoryCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Constants.categoryCellID, for: indexPath) as? CategoryTableViewCell else {
            return UITableViewCell()
        }

        let categoryIndex = indexPath.row - 1
        guard categoryIndex < viewModel.categories.count else { return cell }

        cell.configure(with: viewModel.categories[categoryIndex])
        cell.didTapMovie = { [weak self] movie in
            Navigator.shared.navigateToMovieDetail(with: movie, from: self?.navigationController)
        }
        return cell
    }
}

extension HomeViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text ?? ""
        viewModel.search(query: query)
    }
}

extension UISearchBar {
    func applyFilmTheme() {
        self.placeholder = "Search our movie database"
        self.tintColor = .white
        self.barStyle = .black
        self.searchTextField.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        self.searchTextField.textColor = .white
    }
}
