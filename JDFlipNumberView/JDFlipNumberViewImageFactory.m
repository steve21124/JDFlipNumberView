//
//  JDFlipNumberViewImageFactory.m
//  FlipNumberViewExample
//
//  Created by Markus Emrich on 05.12.12.
//  Copyright (c) 2012 markusemrich. All rights reserved.
//

#import "JDFlipNumberViewImageFactory.h"

@interface JDFlipNumberViewImageFactory ()
@property (nonatomic, strong) NSMutableDictionary *topImages;
@property (nonatomic, strong) NSMutableDictionary *bottomImages;
@end

@implementation JDFlipNumberViewImageFactory

+ (instancetype)sharedInstance;
{
    static JDFlipNumberViewImageFactory *_sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    
    return _sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        _topImages = [NSMutableDictionary dictionary];
        _bottomImages = [NSMutableDictionary dictionary];
        
        // register for memory warnings
        [[NSNotificationCenter defaultCenter]
         addObserver:self selector:@selector(didReceiveMemoryWarning:)
         name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

#pragma mark -
#pragma mark getter

- (NSArray *)topImagesForBundleNamed:(NSString *)bundleName;
{
    if ([_topImages[bundleName] count] == 0) {
        [self generateImagesFromBundleNamed:bundleName];
    }
    
    return _topImages[bundleName];
}

- (NSArray *)bottomImagesForBundleNamed:(NSString *)bundleName;
{
    if ([_bottomImages[bundleName] count] == 0) {
        [self generateImagesFromBundleNamed:bundleName];
    }
    
    return _bottomImages[bundleName];
}

- (CGSize)imageSizeForBundleNamed:(NSString *)bundleName;
{
    NSArray *images = self.topImages[bundleName];
    if (images.count > 0) {
        return [images[0] size];
    }
    return CGSizeZero;
}

#pragma mark -
#pragma mark image generation

-(UIImage *)imageFromText:(NSString *)text fontName:(NSString*)fontName fontSize:(CGFloat)fontSize
{
    // set the font type and size
//    UIFont *font = [UIFont systemFontOfSize:fontSize];
    UIFont *font = [UIFont fontWithName:fontName size:fontSize];
    CGSize size  = [text sizeWithFont:font];
    
    // check if UIGraphicsBeginImageContextWithOptions is available (iOS is 4.0+)
    if (UIGraphicsBeginImageContextWithOptions != NULL)
        UIGraphicsBeginImageContextWithOptions(size,NO,0.0);
    else
        // iOS is < 4.0
        UIGraphicsBeginImageContext(size);
    
    // optional: add a shadow, to avoid clipping the shadow you should make the context size bigger
    //
    // CGContextRef ctx = UIGraphicsGetCurrentContext();
    // CGContextSetShadowWithColor(ctx, CGSizeMake(1.0, 1.0), 5.0, [[UIColor grayColor] CGColor]);
    
    // draw in context, you can use also drawInRect:withFont:
    [text drawAtPoint:CGPointMake(0.0, 0.0) withFont:font];
    
    // transfer image
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}
-(BOOL)fontExist:(NSString*)fontName{
    BOOL exist = FALSE;
    // List all fonts on iPhone
    NSArray *familyNames = [[NSArray alloc] initWithArray:[UIFont familyNames]];
    NSArray *fontNames;
    NSInteger indFamily, indFont;
    for (indFamily=0; indFamily<[familyNames count]; ++indFamily)
    {
        //NSLog(@"Family name: %@", [familyNames objectAtIndex:indFamily]);
        fontNames = [[NSArray alloc] initWithArray:
                     [UIFont fontNamesForFamilyName:
                      [familyNames objectAtIndex:indFamily]]];
        for (indFont=0; indFont<[fontNames count]; ++indFont)
        {
            //NSLog(@"    Font name: %@", [fontNames objectAtIndex:indFont]);
            if ([[fontName lowercaseString] isEqualToString:[[fontNames objectAtIndex:indFont] lowercaseString]]) {
                exist = TRUE;
            }
        }
    }
    return exist;
}

- (void)generateImagesFromBundleNamed:(NSString*)bundleName;
{
    // create image array
	NSMutableArray* topImages = [NSMutableArray arrayWithCapacity:10];
	NSMutableArray* bottomImages = [NSMutableArray arrayWithCapacity:10];
	
    // append .bundle to name
    NSString *filename = bundleName;
    if (![filename hasSuffix:@".bundle"]) filename = [NSString stringWithFormat: @"%@.bundle", filename];

    NSString *bundlePath;
    
    //need to check if bundle exist before assigning
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.bundle",bundleName]];
    if ([fileManager fileExistsAtPath:dataPath]) {
        bundlePath = dataPath;
        
        // create bottom and top images
        for (NSInteger digit=0; digit<10; digit++)
        {
            // create path & image
            NSString *imageName = [NSString stringWithFormat: @"%ld.png", (long)digit];
            //NSString *path = [[NSBundle mainBundle] pathForResource:bundleImageName ofType:nil];
            NSString *path = [dataPath stringByAppendingString:[NSString stringWithFormat:@"/%@",imageName]];
            UIImage *sourceImage = [[UIImage alloc] initWithContentsOfFile:path];
            NSAssert(sourceImage != nil, @"Did not find image '%@' in bundle named '%@'", imageName, filename);
            
            // generate & save images
            NSArray *images = [self generateImagesFromImage:sourceImage];
            [topImages addObject:images[0]];
            [bottomImages addObject:images[1]];
        }
        
    }else if ([self fontExist:bundleName]){
        //if bundle not found check if the bundle name is the system available font. if it is load that font instead.
        //create images from system name
        NSError *error=nil;
        //checking if themes directory already exist. if it isnot need to set the whole directory exclude from icloud backup.
        if (! [fileManager fileExistsAtPath:[dataPath stringByDeletingLastPathComponent]]) {
            //directtory not exist yet create it
            [fileManager createDirectoryAtPath:[dataPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (! [fileManager fileExistsAtPath:dataPath]) {
            [fileManager createDirectoryAtPath:dataPath withIntermediateDirectories:YES attributes:nil error:&error];
        }
        
        // create bottom and top images
        for (NSInteger digit=0; digit<10; digit++)
        {
            
            // create path & image
            NSString *imageName = [NSString stringWithFormat: @"%ld.png", (long)digit];
            //NSString *path = [[NSBundle mainBundle] pathForResource:bundleImageName ofType:nil];
            NSString *path = [dataPath stringByAppendingString:[NSString stringWithFormat:@"/%@",imageName]];
            UIImage *sourceImage = [self imageFromText:[NSString stringWithFormat:@"%ld",(long)digit] fontName:bundleName fontSize:120];
            [fileManager createFileAtPath:path contents:UIImagePNGRepresentation(sourceImage) attributes:nil];
            
            // generate & save images
            NSArray *images = [self generateImagesFromImage:sourceImage];
            [topImages addObject:images[0]];
            [bottomImages addObject:images[1]];
        }
        
    }else{
        //use default bundle
        bundleName = @"Themes/clocks/4511";
        filename = bundleName;
        if (![filename hasSuffix:@".bundle"]) filename = [NSString stringWithFormat: @"%@.bundle", filename];
        bundlePath = [[NSBundle mainBundle] pathForResource:filename ofType:nil];
        
        NSAssert(bundlePath != nil, @"Bundle named '%@' not found!", filename);
        if (!bundlePath) return;
        
        // create bottom and top images
        for (NSInteger digit=0; digit<10; digit++)
        {
            // create path & image
            NSString *imageName = [NSString stringWithFormat: @"%ld.png", (long)digit];
            NSString *bundleImageName = [NSString stringWithFormat: @"%@/%@", filename, imageName];
            NSString *path = [[NSBundle mainBundle] pathForResource:bundleImageName ofType:nil];
            UIImage *sourceImage = [[UIImage alloc] initWithContentsOfFile:path];
            NSAssert(sourceImage != nil, @"Did not find image '%@' in bundle named '%@'", imageName, filename);
            
            // generate & save images
            NSArray *images = [self generateImagesFromImage:sourceImage];
            [topImages addObject:images[0]];
            [bottomImages addObject:images[1]];
        }
    }

	
    // save images
	self.topImages[bundleName]    = [NSArray arrayWithArray:topImages];
	self.bottomImages[bundleName] = [NSArray arrayWithArray:bottomImages];
}


- (NSArray*)generateImagesFromImage:(UIImage*)image;
{
    NSMutableArray *images = [NSMutableArray array];
    
    for (int i=0; i<2; i++) {
        CGSize size = CGSizeMake(image.size.width, image.size.height/2);
        CGFloat yPoint = (i==0) ? 0 : -size.height;
        
        // draw half of the image in a new image
        UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
        [image drawAtPoint:CGPointMake(0,yPoint)];
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        // save image
        [images addObject:image];
    }
    
    return images;
}

#pragma mark -
#pragma mark memory

- (void)didReceiveMemoryWarning:(NSNotification*)notification;
{
    // remove all saved images
    _topImages = [NSMutableDictionary dictionary];
    _bottomImages = [NSMutableDictionary dictionary];
}

@end
