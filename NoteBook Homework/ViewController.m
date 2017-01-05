#import "ViewController.h"
#import "Notes.h"
#import <CoreData/CoreData.h>
#import "AppDelegate.h"
#import "ContentViewController.h"

//去除 NSlog 时间戳, 使打印更简洁
#define NSLog(FORMAT, ...) fprintf(stderr,"%s\n",[[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);

@interface ViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak  ) IBOutlet UITableView      *tableView;        //表格控件
@property (nonatomic, weak  ) IBOutlet UIBarButtonItem  *addButton;        //"添加记录"按钮
@property (nonatomic, strong) NSManagedObjectContext    *managedObjectContext; //上下文
@property (nonatomic, strong) NSArray< Notes*>          *noteArray;        //实体的数组
@property (nonatomic, strong) NSFetchRequest            *fetch;            //查询
@property (nonatomic, strong) Notes                     *noteOfClickedRow; //被点击的 row 的内容

@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //设置表格背景色, 无内容cell的框线色
    _tableView.backgroundColor = [UIColor colorWithRed:55/255 green:55/255 blue:55/255 alpha:0.8];
    _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    //获取上下文
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    _managedObjectContext    = appDelegate.managedObjectContext;
    
    _fetch = [NSFetchRequest fetchRequestWithEntityName:@"Notes"]; //建立查询
}


#pragma mark 在界面显示前进行表格配置和更新
- (void)viewWillAppear: (BOOL)animated {
    
    //通过查询, 把实体内容导出成数组
    _noteArray = [_managedObjectContext executeFetchRequest:_fetch error:nil];
    
    [self nslogAll]; //打印目前所有记录内容(测试用)
    
    //tableview dataSource 和 delegate 配置
    _tableView.dataSource = self;
    _tableView.delegate   = self;
    
    //让表格重新载入数据, 实现同步更新
    [_tableView reloadData];
}


//成功, 打印全部数据看是否成功
- (void)nslogAll {

    for (Notes *note in _noteArray) {
        NSLog(@"%@",note.content);
    }
    NSLog(@"-------------------------- OVER --------------------------");
}


#pragma mark 配置"添加记录"按钮的方法, 目的是跳转到 contentView
- (IBAction)addClicked: (UIBarButtonItem *)sender {
    
    UIStoryboard     *storyboard   = [UIStoryboard storyboardWithName:@"Main" bundle:nil];

    UIViewController *contentBoard = [storyboard instantiateViewControllerWithIdentifier:@"contentVC"];
    
    [self presentViewController:contentBoard animated:YES completion:nil];
}


//tableViewDataSource 方法的配置
- (NSInteger)numberOfSectionsInTableView: (UITableView *)tableView {
    return 1; //只有一个 section
}

- (NSInteger)tableView: (UITableView *)tableView numberOfRowsInSection: (NSInteger)section {
    return _noteArray.count; //按照数组的成员数显示 row
}


#pragma mark 配置 cell 显示的内容
- (UITableViewCell *)tableView: (UITableView *)tableView
         cellForRowAtIndexPath: (NSIndexPath *)indexPath {

    UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:@"cell"
                                                             forIndexPath:indexPath];

    cell.textLabel.text   = _noteArray[indexPath.row].content;//cell 显示note 的 content 属性内容
    
    return cell;
}


//设置 cell 可以被编辑
- (BOOL)tableView: (UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}


#pragma mark 配置cell 的删除操作
/*  逻辑:
    1. 判断是否是删除编辑模式
    2. 如果是, 获取表数组的这个 cell 对应的那个表
    3. 在上下文里删除这个表, 并通过上下文保存到持久层
    4. 重新生成表数组
    5. 表格重新载入数据, 实现同步更新
 */
-  (void)tableView: (UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        Notes *note = _noteArray[indexPath.row];
        
        [_managedObjectContext deleteObject:note];
        
        [_managedObjectContext save:nil];
        
        _noteArray = [_managedObjectContext executeFetchRequest:_fetch error:nil];
        
        [_tableView reloadData];
        
        [self nslogAll]; //打印新的所有值 (测试用)
    }
}


#pragma mark 实现点击某 cell 跳转到它的 contentView, 并在 contentView 显示该 cell 的完整内容
/*  逻辑: (下面两个方法连在一起使用)
    1. 在 storyBoard 里建立 segue link 两个 viewController, 确保segue在点击cell之后运行, 保证传值成功
    2. 取得被点击 cell 对应的表
    3. 调用 segue, 实现页面跳转, 传值
 */
- (void)tableView: (UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    _noteOfClickedRow = _noteArray[indexPath.row];
    
    [self performSegueWithIdentifier:@"showContent" sender:self];
}

//segue 设置, 要跳转的目标页面的 storyBoard ID 是 showContent
- (void)prepareForSegue: (UIStoryboardSegue *)segue sender:(id)sender {
    
    ContentViewController *destinationController = [segue destinationViewController];
    
    //传值
    if ([segue.identifier isEqualToString:@"showContent"]) {
        
        [destinationController setValue:_noteOfClickedRow forKey:@"note"];
    }
}


@end
