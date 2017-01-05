#import "ContentViewController.h"
#import "AppDelegate.h"

//去除 NSlog 时间戳, 使打印更简洁
#define NSLog(FORMAT, ...) fprintf(stderr,"%s\n",[[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);


@interface ContentViewController ()

@property (nonatomic, weak  ) IBOutlet UIBarButtonItem *deleteButton; //删除按钮
@property (nonatomic, weak  ) IBOutlet UIBarButtonItem *cancelButton; //取消按钮
@property (nonatomic, weak  ) IBOutlet UIBarButtonItem *saveButton;   //保存按钮
@property (nonatomic, weak  ) IBOutlet UITextView      *contentText;  //显示内容的文本框
@property (nonatomic, strong) NSManagedObjectContext   *managedObjectContext; //上下文

@end


@implementation ContentViewController


//页面载入设置
- (void)viewDidLoad {
    [super viewDidLoad];
    
    //取得上下文, 为了之后对数据库的增删改
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    _managedObjectContext    = appDelegate.managedObjectContext;
    
    //取得文本框要显示的内容
    _contentText.text = [_note valueForKey:@"content"];
    
    //如果文本框没有内容, 说明不是 cell 激活的,是添加记录按钮激活的, 此时需要插入一条空白记录待输入
    if (!_contentText.text.length) {
        
        _note = [NSEntityDescription insertNewObjectForEntityForName:@"Notes"
                                              inManagedObjectContext:_managedObjectContext];
    }
}


//删除记录操作,先删除该记录, 然后保存到持久层, 然后回到 tableView 页面
- (IBAction)deleteClicked: (UIBarButtonItem *)sender {
    
    [_managedObjectContext deleteObject:_note];
    
    if ([_managedObjectContext save:nil]) {
        NSLog(@"deleted");
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark 保存按钮方法
/*  逻辑:
    1. 对表赋值
    2. 判断表内数据长度, 如果为0, 不保存, 反之通过上下文保存
    3. 回到 tableView 页面
 */
- (IBAction)saveClicked: (UIBarButtonItem *)sender {
   
    [_note setValue:_contentText.text forKey:@"content"];

    if (!_note.content.length) {
        [_managedObjectContext rollback];
    }
    
    if ([_managedObjectContext save:nil]) {
        NSLog(@"Saved");
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}


//取消按钮方法, 不保存所做的变更, 回到 tableView 页面
- (IBAction)cancelClicked:(UIBarButtonItem *)sender {

    [_managedObjectContext rollback];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
