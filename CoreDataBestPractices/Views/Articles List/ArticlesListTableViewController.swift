//
//  ArticlesListTableViewController.swift
//  CoreDataBestPractices
//
//  Created by Antoine van der Lee on 02/11/2020.
//

import UIKit
import SwiftUI
import CoreData

final class ArticlesListTableViewController: UICollectionViewController {
    private enum Section: CaseIterable {
        case main
    }

    private let viewModel = ArticlesListViewModel()

    private lazy var dataSource: UICollectionViewDiffableDataSource<Section, NSManagedObjectID> = {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, NSManagedObjectID> { cell, indexPath, articleObjectID in
            guard let article = try? PersistentContainer.shared.viewContext.existingObject(with: articleObjectID) as? Article else { return }

            var content = cell.defaultContentConfiguration()
            content.text = article.name

            content.secondaryText = article.categoryName ?? "Uncategorized"
            content.secondaryTextProperties.color = .secondaryLabel
            content.secondaryTextProperties.font = UIFont.preferredFont(forTextStyle: .subheadline)

            content.image = UIImage(systemName: "doc.plaintext")
            content.imageProperties.preferredSymbolConfiguration = .init(font: content.textProperties.font, scale: .large)

            cell.contentConfiguration = content
            cell.accessories = [.disclosureIndicator()]
            cell.tintColor = UIColor(named: "SwiftLee Orange")
        }

        return UICollectionViewDiffableDataSource<Section, NSManagedObjectID>(collectionView: collectionView) { (collectionView, indexPath, articleObjectID) -> UICollectionViewCell? in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: articleObjectID)
        }
    }()

    private lazy var fetchedResultsController: NSFetchedResultsController<Article> = {
        let fetchedResultsController = NSFetchedResultsController<Article>(fetchRequest: viewModel.fetchRequest, managedObjectContext: PersistentContainer.shared.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        return fetchedResultsController
    }()

    init() {
        let config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        let layout = UICollectionViewCompositionalLayout.list(using: config)
        super.init(collectionViewLayout: layout)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Articles"
        setupBarButtonItems()
        try! fetchedResultsController.performFetch()
    }

    private func setupBarButtonItems() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Categories", primaryAction: UIAction(handler: { _ in
            self.presentTagsView()
        }))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), primaryAction: UIAction(handler: { _ in
            self.showMoreOptions()
        }))
        setToolbarItems([
            UIBarButtonItem(title: "Add new article", primaryAction: UIAction(handler: { _ in
                self.presentAddArticleView()
            }))
        ], animated: true)
        navigationController?.setToolbarHidden(false, animated: false)
    }

    // MARK: Presenting Views
    private func showMoreOptions() {
        let alert = UIAlertController(title: "Actions", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Derivation Example", style: .default, handler: { _ in
            PersistentContainer.shared.viewContext.demonstrateDerivedAttribute()
        }))
        alert.addAction(UIAlertAction(title: "Insert 1000 1 by 1", style: .default, handler: { _ in
            try! Article.insertSamplesOneByOne(1000)
        }))
        alert.addAction(UIAlertAction(title: "Insert 1000 In Batch", style: .default, handler: { _ in
            try! Article.insertSamplesInBatch(1000)
        }))
        alert.addAction(UIAlertAction(title: "Delete All 1 by 1", style: .destructive, handler: { _ in
            try! Article.deleteAllOneByOne()
        }))
        alert.addAction(UIAlertAction(title: "Delete All In Batch", style: .destructive, handler: { _ in
            try! Article.deleteAllInBatch()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    private func presentTagsView() {
        let categoriesView = CategoriesView().environment(\.managedObjectContext, PersistentContainer.shared.viewContext)
        let hostingController = UIHostingController(rootView: categoriesView)
        present(hostingController, animated: true, completion: nil)
    }

    private func presentAddArticleView() {
        let articleView = ArticleFormView(dismiss: { self.dismiss(animated: true) }).environment(\.managedObjectContext, PersistentContainer.shared.viewContext)
        let hostingController = UIHostingController(rootView: articleView)
        present(hostingController, animated: true, completion: nil)
    }
}

extension ArticlesListTableViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        dataSource.apply(snapshot as NSDiffableDataSourceSnapshot<Section, NSManagedObjectID>, animatingDifferences: true)
    }
}
