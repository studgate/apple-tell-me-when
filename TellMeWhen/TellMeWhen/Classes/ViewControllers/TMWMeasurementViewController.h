#import <UIKit/UIKit.h> // Apple

#import "TMWRule.h"


@interface TMWMeasurementViewController : UIViewController

@property (assign, nonatomic, getter=isEditingRule) BOOL editingRule;
@property (strong, nonatomic) TMWRule *rule;

@end
