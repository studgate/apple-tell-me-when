#import "TMWRulesSummaryController.h"       // Header

#import "TMWStore.h"                        // TMW (Model)
#import "TMWRule.h"                         // TMW (Model)
#import "TMWAPIService.h"                   // TMW (Model)
#import "TMWStoryboardIDs.h"                // TMW (ViewControllers)
#import "TMWSegueUnwindingRules.h"          // TMW (ViewControllers/Segues)
#import "TMWRuleTransmittersController.h"   // TMW (ViewControllers/Rules)
#import "TMWRuleMeasurementsController.h"   // TMW (ViewControllers/Rules)
#import "TMWRuleThresholdController.h"      // TMW (ViewControllers/Rules)
#import "TMWRuleNamingController.h"         // TMW (ViewControllers/Rules)

#pragma mark - Define

#define TMWRuleSummary_CellIndexForActivator        0
#define TMWRuleSummary_CellIndexForRuleName         1
#define TMWRuleSummary_CellIndexForTransmitterName  2
#define TMWRuleSummary_CellIndexForMeasurement      3
#define TMWRuleSummary_CellIndexForCondition        4

@interface TMWRulesSummaryController () <TMWSegueUnwindingRules>
- (IBAction)activationToogled:(UISwitch *)sender;
@property (strong, nonatomic) IBOutlet UISwitch* activationSwitch;
@property (strong, nonatomic) IBOutlet UILabel* ruleNameLabel;
@property (strong, nonatomic) IBOutlet UILabel* transmitterNameLabel;
@property (strong, nonatomic) IBOutlet UIImageView* measurementImageView;
@property (strong, nonatomic) IBOutlet UILabel* measurementNameLabel;
@property (strong, nonatomic) IBOutlet UILabel* conditionLabel;
@end

@implementation TMWRulesSummaryController

#pragma mark - UIViewController methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _activationSwitch.on = _rule.active;
    _ruleNameLabel.text = _rule.name;
    _transmitterNameLabel.text = _rule.transmitter.name;
    _measurementImageView.image = _rule.icon;
    _measurementNameLabel.text = _rule.type;
    _conditionLabel.text = _rule.thresholdDescription;
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:TMWStoryboardIDs_SegueFromRulesSummaryToTransm])
    {
        TMWRuleTransmittersController* cntrll = (TMWRuleTransmittersController*)segue.destinationViewController;
        cntrll.rule = _rule;
        cntrll.needsServerModification = YES;
    }
    else if ([segue.identifier isEqualToString:TMWStoryboardIDs_SegueFromRulesSummaryToMeasur])
    {
        TMWRuleMeasurementsController* cntrll = (TMWRuleMeasurementsController*)segue.destinationViewController;
        cntrll.rule = _rule;
        cntrll.needsServerModification = YES;
    }
    else if ([segue.identifier isEqualToString:TMWStoryboardIDs_SegueFromRulesSummaryToThresh])
    {
        TMWRuleThresholdController* cntrll = (TMWRuleThresholdController*)segue.destinationViewController;
        cntrll.rule = _rule;
        cntrll.needsServerModification = YES;
    }
    else if ([segue.identifier isEqualToString:TMWStoryboardIDs_SegueFromRulesSummaryToNaming])
    {
        TMWRuleNamingController* cntrll = (TMWRuleNamingController*)segue.destinationViewController;
        cntrll.rule = _rule;
        cntrll.needsServerModification = YES;
    }
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSUInteger const row = indexPath.row;
    if (row == 1) {
        [self performSegueWithIdentifier:TMWStoryboardIDs_SegueFromRulesSummaryToNaming sender:self];
    } else if (row == 2) {
        [self performSegueWithIdentifier:TMWStoryboardIDs_SegueFromRulesSummaryToTransm sender:self];
    } else if (row == 3) {
        [self performSegueWithIdentifier:TMWStoryboardIDs_SegueFromRulesSummaryToMeasur sender:self];
    } else if (row == 4) {
        [self performSegueWithIdentifier:TMWStoryboardIDs_SegueFromRulesSummaryToThresh sender:self];
    }
}

#pragma mark - Private functionality

#pragma mark Navigation functionality

- (IBAction)activationToogled:(UISwitch*)sender
{
    TMWRule* rule = _rule;
    rule.active = sender.on;
    [TMWAPIService setRule:_rule completion:^(NSError* error) {
        if (!error) { return; }
        rule.active = !sender.on;
        [sender setOn:rule.active animated:YES];
    }];
}

- (IBAction)unwindFromRuleTransmitters:(UIStoryboardSegue*)segue
{
    _transmitterNameLabel.text = _rule.transmitter.name;
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:TMWRuleSummary_CellIndexForTransmitterName inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}

- (IBAction)unwindFromRuleMeasurements:(UIStoryboardSegue*)segue
{
    _measurementImageView.image = _rule.icon;
    _measurementNameLabel.text = _rule.type;
    _conditionLabel.text = _rule.thresholdDescription;
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:TMWRuleSummary_CellIndexForMeasurement inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:TMWRuleSummary_CellIndexForCondition inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}

- (IBAction)unwindFromRuleThreshold:(UIStoryboardSegue*)segue
{
    _measurementImageView.image = _rule.icon;
    _measurementNameLabel.text = _rule.type;
    _conditionLabel.text = _rule.thresholdDescription;
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:TMWRuleSummary_CellIndexForMeasurement inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:TMWRuleSummary_CellIndexForCondition inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}

- (IBAction)unwindFromRuleThresholdPacked:(UIStoryboardSegue*)segue
{
    _measurementImageView.image = _rule.icon;
    _measurementNameLabel.text = _rule.type;
    _conditionLabel.text = _rule.thresholdDescription;
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:TMWRuleSummary_CellIndexForMeasurement inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:TMWRuleSummary_CellIndexForCondition inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}

- (IBAction)unwindFromRuleName:(UIStoryboardSegue*)segue
{
    _ruleNameLabel.text = _rule.name;
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:TMWRuleSummary_CellIndexForRuleName inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}


@end
