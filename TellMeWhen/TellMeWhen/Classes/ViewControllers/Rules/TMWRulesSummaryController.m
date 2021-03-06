#import "TMWRulesSummaryController.h"       // Header

#import "TMWStore.h"                        // TMW (Model)
#import "TMWRule.h"                         // TMW (Model)
#import "TMWRuleCondition.h"                // TMW (Model)
#import "TMWAPIService.h"                   // TMW (Model)
#import "TMWLogging.h"                      // TMW (Model)
#import <Relayr/RelayrCloud.h>              // Relayr.framework
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
#define TMWRuleSummary_CellIndexForCurrentValue     5
#define TMWRuleSummary_CellValue(type, num, unit)   [NSString stringWithFormat:@"%@ = %.1f %@", type, ((NSNumber*)num).floatValue, unit]
#define TMWRulesSummaryCntrll_SubscriptionError     @"Error subscripbing to MQTT channel"
#define TMWRulesSummaryCntrll_SubscriptionUnknown   @"N/A"

@interface TMWRulesSummaryController () <TMWSegueUnwindingRules>
- (IBAction)activationToogled:(UISwitch*)sender;
@property (strong, nonatomic) IBOutlet UISwitch* activationSwitch;
@property (strong, nonatomic) IBOutlet UILabel* ruleNameLabel;
@property (strong, nonatomic) IBOutlet UILabel* transmitterNameLabel;
@property (strong, nonatomic) IBOutlet UIImageView* measurementImageView;
@property (strong, nonatomic) IBOutlet UILabel* measurementNameLabel;
@property (strong, nonatomic) IBOutlet UILabel* conditionLabel;
@property (strong, nonatomic) IBOutlet UILabel* currentValueLabel;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView* currentValueIndicator;
@end

@implementation TMWRulesSummaryController

#pragma mark NSObject

- (void)dealloc
{
    NSString* meaning = _rule.condition.meaning;
    RelayrDevice* device = [_rule.transmitter devicesWithInputMeaning:meaning].anyObject;
    [[device inputWithMeaning:meaning] unsubscribeTarget:self action:@selector(dataArrivedFromDevice:withInput:)];
}

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
    
    __weak TMWRulesSummaryController* weakSelf = self;
    [self subscribeToRule:_rule withTarget:self action:@selector(dataArrivedFromDevice:withInput:) withErrorBlock:^(NSError* error) {
        TMWRulesSummaryController* strongSelf = weakSelf;
        if (!strongSelf) { return; }
        
        [strongSelf.currentValueIndicator stopAnimating];
        strongSelf.currentValueIndicator.hidden = YES;
        
        strongSelf.currentValueLabel.text = TMWRulesSummaryCntrll_SubscriptionError;
        strongSelf.currentValueLabel.hidden = NO;
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:TMWStoryboardIDs_SegueFromRulesSummaryToTransm])
    {
        [RelayrCloud logMessage:TMWLogging_Edit_Transmitter onBehalfOfUser:[TMWStore sharedInstance].relayrUser];
        TMWRuleTransmittersController* cntrll = (TMWRuleTransmittersController*)segue.destinationViewController;
        cntrll.rule = _rule;
        cntrll.needsServerModification = YES;
    }
    else if ([segue.identifier isEqualToString:TMWStoryboardIDs_SegueFromRulesSummaryToMeasur])
    {
        [RelayrCloud logMessage:TMWLogging_Edit_Sensor onBehalfOfUser:[TMWStore sharedInstance].relayrUser];
        TMWRuleMeasurementsController* cntrll = (TMWRuleMeasurementsController*)segue.destinationViewController;
        cntrll.rule = _rule;
        cntrll.needsServerModification = YES;
    }
    else if ([segue.identifier isEqualToString:TMWStoryboardIDs_SegueFromRulesSummaryToThresh])
    {
        [RelayrCloud logMessage:TMWLogging_Edit_Threshold onBehalfOfUser:[TMWStore sharedInstance].relayrUser];
        TMWRuleThresholdController* cntrll = (TMWRuleThresholdController*)segue.destinationViewController;
        cntrll.rule = _rule;
        cntrll.needsServerModification = YES;
    }
    else if ([segue.identifier isEqualToString:TMWStoryboardIDs_SegueFromRulesSummaryToNaming])
    {
        [RelayrCloud logMessage:TMWLogging_Edit_Name onBehalfOfUser:[TMWStore sharedInstance].relayrUser];
        TMWRuleNamingController* cntrll = (TMWRuleNamingController*)segue.destinationViewController;
        cntrll.rule = _rule;
        cntrll.needsServerModification = YES;
    }
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSUInteger const row = indexPath.row;
    if (row == 0) {
        [_activationSwitch setOn:!_activationSwitch.on animated:YES];
        [self activationToogled:_activationSwitch];
    } else if (row == 1) {
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

- (void)subscribeToRule:(TMWRule*)rule withTarget:(id)target action:(SEL)action withErrorBlock:(void (^)(NSError* error))errorBlock
{
    NSString* meaning = rule.condition.meaning;
    RelayrDevice* device = [rule.transmitter devicesWithInputMeaning:meaning].anyObject;
    RelayrInput* input = [device inputWithMeaning:meaning];
    if (!rule || !input) { if (errorBlock) { errorBlock(RelayrErrorMQTTSubscriptionFailed); } return; }
    
    [input subscribeWithTarget:target action:action error:errorBlock];
}

- (void)dataArrivedFromDevice:(RelayrDevice*)device withInput:(RelayrInput*)input
{
    if (!_currentValueIndicator.hidden)
    {
        [_currentValueIndicator stopAnimating];
        _currentValueIndicator.hidden = YES;
        _currentValueLabel.hidden = NO;
    }
    
    _currentValueLabel.text = ([input.value isKindOfClass:[NSNumber class]]) ?
    TMWRuleSummary_CellValue(_rule.type, [TMWRuleCondition convertServerValue:input.value withMeaning:_rule.condition.meaning], _rule.condition.unit) :
    TMWRulesSummaryCntrll_SubscriptionUnknown;
}

#pragma mark Navigation functionality

- (IBAction)activationToogled:(UISwitch*)sender
{
    TMWRule* rule = _rule;
    rule.active = sender.on;
    [TMWAPIService setRule:_rule completion:^(NSError* error) {
        if (!error) { [RelayrCloud logMessage:TMWLogging_Edit_Switch(rule.active) onBehalfOfUser:[TMWStore sharedInstance].relayrUser]; return; }
        
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
