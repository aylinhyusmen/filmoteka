import UIKit

final class MovieSearchViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private enum Constants {
        static let searchCellID = "SearchCell"
    }
    
    var onMovieSelected: ((MediaItem) -> Void)?
    private let viewModel = MovieSearchViewModel()
    
    private lazy var searchBar: UISearchBar = {
        let bar = UISearchBar()
        bar.applyFilmTheme()
        bar.showsCancelButton = true
        bar.delegate = self
        return bar
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.cancelSearch()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(named: "DeepDark")
        
        navigationController?.navigationBar.barTintColor = UIColor(named: "DeepDark")
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.tintColor = .white
        
        navigationItem.titleView = searchBar
    }
    
    private func bindViewModel() {
        viewModel.onSearchResultsUpdated = { [weak self] in
            self?.tableView.reloadData()
        }
        
        viewModel.onError = { errorMessage in
            print("Search failed: \(errorMessage)")
        }
    }
}

extension MovieSearchViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.search(query: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        dismiss(animated: true)
    }
}

extension MovieSearchViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.searchCellID) ?? UITableViewCell(style: .subtitle, reuseIdentifier: Constants.searchCellID)
        
        guard let movie = viewModel.movie(at: indexPath.row) else { return cell }
        
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let selectedMovie = viewModel.movie(at: indexPath.row) else { return }
        
        searchBar.resignFirstResponder()
        onMovieSelected?(selectedMovie)
        dismiss(animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        90
    }
}
