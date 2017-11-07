/*
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import RxSwift
import RxCocoa

final class CategoriesViewController: UIViewController {

    // MARK: - IBOutlet
    @IBOutlet var tableView: UITableView!

    // MARK: - properties
    fileprivate let categories = Variable<[EOCategory]>([])
    fileprivate let bag = DisposeBag()

    // MARK: - Life circle
    override func viewDidLoad() {
        super.viewDidLoad()
        categories.asObservable()
            .subscribe(onNext: { [weak self] _ in
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            }).addDisposableTo(bag)
        startDownload()
    }

    // MARK: - Public func
    func startDownload() {
        let eoCategories = EONET.categories
        let downloadedEvents = EONET.events(forLast: 360)
        let updateCategories = Observable.combineLatest(eoCategories, downloadedEvents) {
            (categories, events) -> [EOCategory] in
            return categories.map { category in
                var cate = category
                cate.events = events.filter {
                    $0.categories.contains(category.id)
                }
                return cate
            }
        }
        eoCategories
        .concat(updateCategories)
        .bindTo(categories)
        .addDisposableTo(bag)
    }
}

// MARK: - extension UITableViewDataSource
extension CategoriesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.value.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell")!
        let category = categories.value[indexPath.row]
        cell.textLabel?.text = "\(category.name) (\(category.events.count))"
        cell.accessoryType = (category.events.count > 0) ? .disclosureIndicator : .none
        return cell
    }
}

// MARK: - extension UITableViewDelegate
extension CategoriesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let category = categories.value[indexPath.row]
        if !category.events.isEmpty {
            let eventsController = storyboard?.instantiateViewController(withIdentifier: "events") as! EventsViewController
            eventsController.title = category.name
            eventsController.events.value = category.events
            navigationController?.pushViewController(eventsController, animated: true)
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}

