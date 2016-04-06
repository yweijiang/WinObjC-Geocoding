//******************************************************************************
//
// Copyright (c) 2016 Intel Corporation. All rights reserved.
// Copyright (c) 2016 Microsoft Corporation. All rights reserved.
//
// This code is licensed under the MIT License (MIT).
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
//******************************************************************************

#import <ImageIO/CGImageProperties.h>
#import <StubReturn.h>

const CFStringRef kCGImagePropertyTIFFDictionary = static_cast<CFStringRef>(@"kCGImagePropertyTIFFDictionary");
const CFStringRef kCGImagePropertyGIFDictionary = static_cast<CFStringRef>(@"kCGImagePropertyGIFDictionary");
const CFStringRef kCGImagePropertyJFIFDictionary = static_cast<CFStringRef>(@"kCGImagePropertyJFIFDictionary");
const CFStringRef kCGImagePropertyExifDictionary = static_cast<CFStringRef>(@"kCGImagePropertyExifDictionary");
const CFStringRef kCGImagePropertyPNGDictionary = static_cast<CFStringRef>(@"kCGImagePropertyPNGDictionary");
const CFStringRef kCGImagePropertyIPTCDictionary = static_cast<CFStringRef>(@"kCGImagePropertyIPTCDictionary");
const CFStringRef kCGImagePropertyGPSDictionary = static_cast<CFStringRef>(@"kCGImagePropertyGPSDictionary");
const CFStringRef kCGImagePropertyRawDictionary = static_cast<CFStringRef>(@"kCGImagePropertyRawDictionary");
const CFStringRef kCGImagePropertyCIFFDictionary = static_cast<CFStringRef>(@"kCGImagePropertyCIFFDictionary");
const CFStringRef kCGImageProperty8BIMDictionary = static_cast<CFStringRef>(@"kCGImageProperty8BIMDictionary");
const CFStringRef kCGImagePropertyDNGDictionary = static_cast<CFStringRef>(@"kCGImagePropertyDNGDictionary");
const CFStringRef kCGImagePropertyExifAuxDictionary = static_cast<CFStringRef>(@"kCGImagePropertyExifAuxDictionary");
const CFStringRef kCGImagePropertyMakerCanonDictionary = static_cast<CFStringRef>(@"kCGImagePropertyMakerCanonDictionary");
const CFStringRef kCGImagePropertyMakerNikonDictionary = static_cast<CFStringRef>(@"kCGImagePropertyMakerNikonDictionary");
const CFStringRef kCGImagePropertyMakerMinoltaDictionary = static_cast<CFStringRef>(@"kCGImagePropertyMakerMinoltaDictionary");
const CFStringRef kCGImagePropertyMakerFujiDictionary = static_cast<CFStringRef>(@"kCGImagePropertyMakerFujiDictionary");
const CFStringRef kCGImagePropertyMakerOlympusDictionary = static_cast<CFStringRef>(@"kCGImagePropertyMakerOlympusDictionary");
const CFStringRef kCGImagePropertyMakerPentaxDictionary = static_cast<CFStringRef>(@"kCGImagePropertyMakerPentaxDictionary");
const CFStringRef kCGImagePropertyFileSize = static_cast<CFStringRef>(@"FileSize");
const CFStringRef kCGImagePropertyDPIHeight = static_cast<CFStringRef>(@"DPIHeight");
const CFStringRef kCGImagePropertyDPIWidth = static_cast<CFStringRef>(@"DPIWidth");
const CFStringRef kCGImagePropertyPixelWidth = static_cast<CFStringRef>(@"PixelWidth");
const CFStringRef kCGImagePropertyPixelHeight = static_cast<CFStringRef>(@"PixelHeight");
const CFStringRef kCGImagePropertyDepth = static_cast<CFStringRef>(@"Depth");
const CFStringRef kCGImagePropertyOrientation = static_cast<CFStringRef>(@"Orientation");
const CFStringRef kCGImagePropertyIsFloat = static_cast<CFStringRef>(@"IsFloat");
const CFStringRef kCGImagePropertyIsIndexed = static_cast<CFStringRef>(@"IsIndexed");
const CFStringRef kCGImagePropertyHasAlpha = static_cast<CFStringRef>(@"HasAlpha");
const CFStringRef kCGImagePropertyColorModel = static_cast<CFStringRef>(@"ColorModel");
const CFStringRef kCGImagePropertyProfileName = static_cast<CFStringRef>(@"ProfileName");
const CFStringRef kCGImagePropertyColorModelRGB = static_cast<CFStringRef>(@"ColorModelRGB");
const CFStringRef kCGImagePropertyColorModelGray = static_cast<CFStringRef>(@"ColorModelGray");
const CFStringRef kCGImagePropertyColorModelCMYK = static_cast<CFStringRef>(@"ColorModelCMYK");
const CFStringRef kCGImagePropertyColorModelLab = static_cast<CFStringRef>(@"ColorModelLab");
const CFStringRef kCGImagePropertyExifExposureTime = static_cast<CFStringRef>(@"kCGImagePropertyExifExposureTime");
const CFStringRef kCGImagePropertyExifFNumber = static_cast<CFStringRef>(@"kCGImagePropertyExifFNumber");
const CFStringRef kCGImagePropertyExifExposureProgram = static_cast<CFStringRef>(@"kCGImagePropertyExifExposureProgram");
const CFStringRef kCGImagePropertyExifSpectralSensitivity = static_cast<CFStringRef>(@"kCGImagePropertyExifSpectralSensitivity");
const CFStringRef kCGImagePropertyExifISOSpeedRatings = static_cast<CFStringRef>(@"kCGImagePropertyExifISOSpeedRatings");
const CFStringRef kCGImagePropertyExifOECF = static_cast<CFStringRef>(@"kCGImagePropertyExifOECF");
const CFStringRef kCGImagePropertyExifVersion = static_cast<CFStringRef>(@"kCGImagePropertyExifVersion");
const CFStringRef kCGImagePropertyExifDateTimeOriginal = static_cast<CFStringRef>(@"kCGImagePropertyExifDateTimeOriginal");
const CFStringRef kCGImagePropertyExifDateTimeDigitized = static_cast<CFStringRef>(@"kCGImagePropertyExifDateTimeDigitized");
const CFStringRef kCGImagePropertyExifComponentsConfiguration = static_cast<CFStringRef>(@"kCGImagePropertyExifComponentsConfiguration");
const CFStringRef kCGImagePropertyExifCompressedBitsPerPixel = static_cast<CFStringRef>(@"kCGImagePropertyExifCompressedBitsPerPixel");
const CFStringRef kCGImagePropertyExifShutterSpeedValue = static_cast<CFStringRef>(@"kCGImagePropertyExifShutterSpeedValue");
const CFStringRef kCGImagePropertyExifApertureValue = static_cast<CFStringRef>(@"kCGImagePropertyExifApertureValue");
const CFStringRef kCGImagePropertyExifBrightnessValue = static_cast<CFStringRef>(@"kCGImagePropertyExifBrightnessValue");
const CFStringRef kCGImagePropertyExifExposureBiasValue = static_cast<CFStringRef>(@"kCGImagePropertyExifExposureBiasValue");
const CFStringRef kCGImagePropertyExifMaxApertureValue = static_cast<CFStringRef>(@"kCGImagePropertyExifMaxApertureValue");
const CFStringRef kCGImagePropertyExifSubjectDistance = static_cast<CFStringRef>(@"kCGImagePropertyExifSubjectDistance");
const CFStringRef kCGImagePropertyExifMeteringMode = static_cast<CFStringRef>(@"kCGImagePropertyExifMeteringMode");
const CFStringRef kCGImagePropertyExifLightSource = static_cast<CFStringRef>(@"kCGImagePropertyExifLightSource");
const CFStringRef kCGImagePropertyExifFlash = static_cast<CFStringRef>(@"kCGImagePropertyExifFlash");
const CFStringRef kCGImagePropertyExifFocalLength = static_cast<CFStringRef>(@"kCGImagePropertyExifFocalLength");
const CFStringRef kCGImagePropertyExifSubjectArea = static_cast<CFStringRef>(@"kCGImagePropertyExifSubjectArea");
const CFStringRef kCGImagePropertyExifMakerNote = static_cast<CFStringRef>(@"kCGImagePropertyExifMakerNote");
const CFStringRef kCGImagePropertyExifUserComment = static_cast<CFStringRef>(@"kCGImagePropertyExifUserComment");
const CFStringRef kCGImagePropertyExifSubsecTime = static_cast<CFStringRef>(@"kCGImagePropertyExifSubsecTime");
const CFStringRef kCGImagePropertyExifSubsecTimeOrginal = static_cast<CFStringRef>(@"kCGImagePropertyExifSubsecTimeOrginal");
const CFStringRef kCGImagePropertyExifSubsecTimeDigitized = static_cast<CFStringRef>(@"kCGImagePropertyExifSubsecTimeDigitized");
const CFStringRef kCGImagePropertyExifFlashPixVersion = static_cast<CFStringRef>(@"kCGImagePropertyExifFlashPixVersion");
const CFStringRef kCGImagePropertyExifColorSpace = static_cast<CFStringRef>(@"kCGImagePropertyExifColorSpace");
const CFStringRef kCGImagePropertyExifPixelXDimension = static_cast<CFStringRef>(@"kCGImagePropertyExifPixelXDimension");
const CFStringRef kCGImagePropertyExifPixelYDimension = static_cast<CFStringRef>(@"kCGImagePropertyExifPixelYDimension");
const CFStringRef kCGImagePropertyExifRelatedSoundFile = static_cast<CFStringRef>(@"kCGImagePropertyExifRelatedSoundFile");
const CFStringRef kCGImagePropertyExifFlashEnergy = static_cast<CFStringRef>(@"kCGImagePropertyExifFlashEnergy");
const CFStringRef kCGImagePropertyExifSpatialFrequencyResponse = static_cast<CFStringRef>(@"kCGImagePropertyExifSpatialFrequencyResponse");
const CFStringRef kCGImagePropertyExifFocalPlaneXResolution = static_cast<CFStringRef>(@"kCGImagePropertyExifFocalPlaneXResolution");
const CFStringRef kCGImagePropertyExifFocalPlaneYResolution = static_cast<CFStringRef>(@"kCGImagePropertyExifFocalPlaneYResolution");
const CFStringRef kCGImagePropertyExifFocalPlaneResolutionUnit = static_cast<CFStringRef>(@"kCGImagePropertyExifFocalPlaneResolutionUnit");
const CFStringRef kCGImagePropertyExifSubjectLocation = static_cast<CFStringRef>(@"kCGImagePropertyExifSubjectLocation");
const CFStringRef kCGImagePropertyExifExposureIndex = static_cast<CFStringRef>(@"kCGImagePropertyExifExposureIndex");
const CFStringRef kCGImagePropertyExifSensingMethod = static_cast<CFStringRef>(@"kCGImagePropertyExifSensingMethod");
const CFStringRef kCGImagePropertyExifFileSource = static_cast<CFStringRef>(@"kCGImagePropertyExifFileSource");
const CFStringRef kCGImagePropertyExifSceneType = static_cast<CFStringRef>(@"kCGImagePropertyExifSceneType");
const CFStringRef kCGImagePropertyExifCFAPattern = static_cast<CFStringRef>(@"kCGImagePropertyExifCFAPattern");
const CFStringRef kCGImagePropertyExifCustomRendered = static_cast<CFStringRef>(@"kCGImagePropertyExifCustomRendered");
const CFStringRef kCGImagePropertyExifExposureMode = static_cast<CFStringRef>(@"kCGImagePropertyExifExposureMode");
const CFStringRef kCGImagePropertyExifWhiteBalance = static_cast<CFStringRef>(@"kCGImagePropertyExifWhiteBalance");
const CFStringRef kCGImagePropertyExifDigitalZoomRatio = static_cast<CFStringRef>(@"kCGImagePropertyExifDigitalZoomRatio");
const CFStringRef kCGImagePropertyExifFocalLenIn35mmFilm = static_cast<CFStringRef>(@"kCGImagePropertyExifFocalLenIn35mmFilm");
const CFStringRef kCGImagePropertyExifSceneCaptureType = static_cast<CFStringRef>(@"kCGImagePropertyExifSceneCaptureType");
const CFStringRef kCGImagePropertyExifGainControl = static_cast<CFStringRef>(@"kCGImagePropertyExifGainControl");
const CFStringRef kCGImagePropertyExifContrast = static_cast<CFStringRef>(@"kCGImagePropertyExifContrast");
const CFStringRef kCGImagePropertyExifSaturation = static_cast<CFStringRef>(@"kCGImagePropertyExifSaturation");
const CFStringRef kCGImagePropertyExifSharpness = static_cast<CFStringRef>(@"kCGImagePropertyExifSharpness");
const CFStringRef kCGImagePropertyExifDeviceSettingDescription = static_cast<CFStringRef>(@"kCGImagePropertyExifDeviceSettingDescription");
const CFStringRef kCGImagePropertyExifSubjectDistRange = static_cast<CFStringRef>(@"kCGImagePropertyExifSubjectDistRange");
const CFStringRef kCGImagePropertyExifImageUniqueID = static_cast<CFStringRef>(@"kCGImagePropertyExifImageUniqueID");
const CFStringRef kCGImagePropertyExifGamma = static_cast<CFStringRef>(@"kCGImagePropertyExifGamma");
const CFStringRef kCGImagePropertyExifCameraOwnerName = static_cast<CFStringRef>(@"kCGImagePropertyExifCameraOwnerName");
const CFStringRef kCGImagePropertyExifBodySerialNumber = static_cast<CFStringRef>(@"kCGImagePropertyExifBodySerialNumber");
const CFStringRef kCGImagePropertyExifLensSpecification = static_cast<CFStringRef>(@"kCGImagePropertyExifLensSpecification");
const CFStringRef kCGImagePropertyExifLensMake = static_cast<CFStringRef>(@"kCGImagePropertyExifLensMake");
const CFStringRef kCGImagePropertyExifLensModel = static_cast<CFStringRef>(@"kCGImagePropertyExifLensModel");
const CFStringRef kCGImagePropertyExifLensSerialNumber = static_cast<CFStringRef>(@"kCGImagePropertyExifLensSerialNumber");
const CFStringRef kCGImagePropertyExifAuxLensInfo = static_cast<CFStringRef>(@"kCGImagePropertyExifAuxLensInfo");
const CFStringRef kCGImagePropertyExifAuxLensModel = static_cast<CFStringRef>(@"kCGImagePropertyExifAuxLensModel");
const CFStringRef kCGImagePropertyExifAuxSerialNumber = static_cast<CFStringRef>(@"");
const CFStringRef kCGImagePropertyExifAuxLensID = static_cast<CFStringRef>(@"kCGImagePropertyExifAuxLensID");
const CFStringRef kCGImagePropertyExifAuxLensSerialNumber = static_cast<CFStringRef>(@"kCGImagePropertyExifAuxLensSerialNumber");
const CFStringRef kCGImagePropertyExifAuxImageNumber = static_cast<CFStringRef>(@"kCGImagePropertyExifAuxImageNumber");
const CFStringRef kCGImagePropertyExifAuxFlashCompensation = static_cast<CFStringRef>(@"kCGImagePropertyExifAuxFlashCompensation");
const CFStringRef kCGImagePropertyExifAuxOwnerName = static_cast<CFStringRef>(@"kCGImagePropertyExifAuxOwnerName");
const CFStringRef kCGImagePropertyExifAuxFirmware = static_cast<CFStringRef>(@"");
const CFStringRef kCGImagePropertyGIFLoopCount = static_cast<CFStringRef>(@"LoopCount");
const CFStringRef kCGImagePropertyGIFDelayTime = static_cast<CFStringRef>(@"DelayTime");
const CFStringRef kCGImagePropertyGIFImageColorMap = static_cast<CFStringRef>(@"ImageColorMap");
const CFStringRef kCGImagePropertyGIFHasGlobalColorMap = static_cast<CFStringRef>(@"HasGlobalColorMap");
const CFStringRef kCGImagePropertyGIFUnclampedDelayTime = static_cast<CFStringRef>(@"UnclampedDelayTime");
const CFStringRef kCGImagePropertyGPSVersion = static_cast<CFStringRef>(@"kCGImagePropertyGPSVersion");
const CFStringRef kCGImagePropertyGPSLatitudeRef = static_cast<CFStringRef>(@"kCGImagePropertyGPSLatitudeRef");
const CFStringRef kCGImagePropertyGPSLatitude = static_cast<CFStringRef>(@"kCGImagePropertyGPSLatitude");
const CFStringRef kCGImagePropertyGPSLongitudeRef = static_cast<CFStringRef>(@"kCGImagePropertyGPSLongitudeRef");
const CFStringRef kCGImagePropertyGPSLongitude = static_cast<CFStringRef>(@"kCGImagePropertyGPSLongitude");
const CFStringRef kCGImagePropertyGPSAltitudeRef = static_cast<CFStringRef>(@"kCGImagePropertyGPSAltitudeRef");
const CFStringRef kCGImagePropertyGPSAltitude = static_cast<CFStringRef>(@"kCGImagePropertyGPSAltitude");
const CFStringRef kCGImagePropertyGPSTimeStamp = static_cast<CFStringRef>(@"kCGImagePropertyGPSTimeStamp");
const CFStringRef kCGImagePropertyGPSSatellites = static_cast<CFStringRef>(@"kCGImagePropertyGPSSatellites");
const CFStringRef kCGImagePropertyGPSStatus = static_cast<CFStringRef>(@"kCGImagePropertyGPSStatus");
const CFStringRef kCGImagePropertyGPSMeasureMode = static_cast<CFStringRef>(@"kCGImagePropertyGPSMeasureMode");
const CFStringRef kCGImagePropertyGPSDOP = static_cast<CFStringRef>(@"kCGImagePropertyGPSDOP");
const CFStringRef kCGImagePropertyGPSSpeedRef = static_cast<CFStringRef>(@"kCGImagePropertyGPSSpeedRef");
const CFStringRef kCGImagePropertyGPSSpeed = static_cast<CFStringRef>(@"kCGImagePropertyGPSSpeed");
const CFStringRef kCGImagePropertyGPSTrackRef = static_cast<CFStringRef>(@"kCGImagePropertyGPSTrackRef");
const CFStringRef kCGImagePropertyGPSTrack = static_cast<CFStringRef>(@"kCGImagePropertyGPSTrack");
const CFStringRef kCGImagePropertyGPSImgDirectionRef = static_cast<CFStringRef>(@"kCGImagePropertyGPSImgDirectionRef");
const CFStringRef kCGImagePropertyGPSImgDirection = static_cast<CFStringRef>(@"kCGImagePropertyGPSImgDirection");
const CFStringRef kCGImagePropertyGPSMapDatum = static_cast<CFStringRef>(@"kCGImagePropertyGPSMapDatum");
const CFStringRef kCGImagePropertyGPSDestLatitudeRef = static_cast<CFStringRef>(@"kCGImagePropertyGPSDestLatitudeRef");
const CFStringRef kCGImagePropertyGPSDestLatitude = static_cast<CFStringRef>(@"kCGImagePropertyGPSDestLatitude");
const CFStringRef kCGImagePropertyGPSDestLongitudeRef = static_cast<CFStringRef>(@"kCGImagePropertyGPSDestLongitudeRef");
const CFStringRef kCGImagePropertyGPSDestLongitude = static_cast<CFStringRef>(@"kCGImagePropertyGPSDestLongitude");
const CFStringRef kCGImagePropertyGPSDestBearingRef = static_cast<CFStringRef>(@"kCGImagePropertyGPSDestBearingRef");
const CFStringRef kCGImagePropertyGPSDestBearing = static_cast<CFStringRef>(@"kCGImagePropertyGPSDestBearing");
const CFStringRef kCGImagePropertyGPSDestDistanceRef = static_cast<CFStringRef>(@"kCGImagePropertyGPSDestDistanceRef");
const CFStringRef kCGImagePropertyGPSDestDistance = static_cast<CFStringRef>(@"kCGImagePropertyGPSDestDistance");
const CFStringRef kCGImagePropertyGPSProcessingMethod = static_cast<CFStringRef>(@"kCGImagePropertyGPSProcessingMethod");
const CFStringRef kCGImagePropertyGPSAreaInformation = static_cast<CFStringRef>(@"kCGImagePropertyGPSAreaInformation");
const CFStringRef kCGImagePropertyGPSDateStamp = static_cast<CFStringRef>(@"kCGImagePropertyGPSDateStamp");
const CFStringRef kCGImagePropertyGPSDifferental = static_cast<CFStringRef>(@"kCGImagePropertyGPSDifferental");
const CFStringRef kCGImagePropertyIPTCObjectTypeReference = static_cast<CFStringRef>(@"kCGImagePropertyIPTCObjectTypeReference");
const CFStringRef kCGImagePropertyIPTCObjectAttributeReference = static_cast<CFStringRef>(@"kCGImagePropertyIPTCObjectAttributeReference");
const CFStringRef kCGImagePropertyIPTCObjectName = static_cast<CFStringRef>(@"kCGImagePropertyIPTCObjectName");
const CFStringRef kCGImagePropertyIPTCEditStatus = static_cast<CFStringRef>(@"kCGImagePropertyIPTCEditStatus");
const CFStringRef kCGImagePropertyIPTCEditorialUpdate = static_cast<CFStringRef>(@"kCGImagePropertyIPTCEditorialUpdate");
const CFStringRef kCGImagePropertyIPTCUrgency = static_cast<CFStringRef>(@"kCGImagePropertyIPTCUrgency");
const CFStringRef kCGImagePropertyIPTCSubjectReference = static_cast<CFStringRef>(@"kCGImagePropertyIPTCSubjectReference");
const CFStringRef kCGImagePropertyIPTCCategory = static_cast<CFStringRef>(@"kCGImagePropertyIPTCCategory");
const CFStringRef kCGImagePropertyIPTCSupplementalCategory = static_cast<CFStringRef>(@"kCGImagePropertyIPTCSupplementalCategory");
const CFStringRef kCGImagePropertyIPTCFixtureIdentifier = static_cast<CFStringRef>(@"kCGImagePropertyIPTCFixtureIdentifier");
const CFStringRef kCGImagePropertyIPTCKeywords = static_cast<CFStringRef>(@"kCGImagePropertyIPTCKeywords");
const CFStringRef kCGImagePropertyIPTCContentLocationCode = static_cast<CFStringRef>(@"kCGImagePropertyIPTCContentLocationCode");
const CFStringRef kCGImagePropertyIPTCContentLocationName = static_cast<CFStringRef>(@"kCGImagePropertyIPTCContentLocationName");
const CFStringRef kCGImagePropertyIPTCReleaseDate = static_cast<CFStringRef>(@"kCGImagePropertyIPTCReleaseDate");
const CFStringRef kCGImagePropertyIPTCReleaseTime = static_cast<CFStringRef>(@"kCGImagePropertyIPTCReleaseTime");
const CFStringRef kCGImagePropertyIPTCExpirationDate = static_cast<CFStringRef>(@"kCGImagePropertyIPTCExpirationDate");
const CFStringRef kCGImagePropertyIPTCExpirationTime = static_cast<CFStringRef>(@"kCGImagePropertyIPTCExpirationTime");
const CFStringRef kCGImagePropertyIPTCSpecialInstructions = static_cast<CFStringRef>(@"kCGImagePropertyIPTCSpecialInstructions");
const CFStringRef kCGImagePropertyIPTCActionAdvised = static_cast<CFStringRef>(@"kCGImagePropertyIPTCActionAdvised");
const CFStringRef kCGImagePropertyIPTCReferenceService = static_cast<CFStringRef>(@"kCGImagePropertyIPTCReferenceService");
const CFStringRef kCGImagePropertyIPTCReferenceDate = static_cast<CFStringRef>(@"kCGImagePropertyIPTCReferenceDate");
const CFStringRef kCGImagePropertyIPTCReferenceNumber = static_cast<CFStringRef>(@"kCGImagePropertyIPTCReferenceNumber");
const CFStringRef kCGImagePropertyIPTCDateCreated = static_cast<CFStringRef>(@"kCGImagePropertyIPTCDateCreated");
const CFStringRef kCGImagePropertyIPTCTimeCreated = static_cast<CFStringRef>(@"kCGImagePropertyIPTCTimeCreated");
const CFStringRef kCGImagePropertyIPTCDigitalCreationDate = static_cast<CFStringRef>(@"kCGImagePropertyIPTCDigitalCreationDate");
const CFStringRef kCGImagePropertyIPTCDigitalCreationTime = static_cast<CFStringRef>(@"kCGImagePropertyIPTCDigitalCreationTime");
const CFStringRef kCGImagePropertyIPTCOriginatingProgram = static_cast<CFStringRef>(@"kCGImagePropertyIPTCDigitalCreationTime");
const CFStringRef kCGImagePropertyIPTCProgramVersion = static_cast<CFStringRef>(@"kCGImagePropertyIPTCProgramVersion");
const CFStringRef kCGImagePropertyIPTCObjectCycle = static_cast<CFStringRef>(@"kCGImagePropertyIPTCObjectCycle");
const CFStringRef kCGImagePropertyIPTCByline = static_cast<CFStringRef>(@"kCGImagePropertyIPTCByline");
const CFStringRef kCGImagePropertyIPTCBylineTitle = static_cast<CFStringRef>(@"kCGImagePropertyIPTCBylineTitle");
const CFStringRef kCGImagePropertyIPTCCity = static_cast<CFStringRef>(@"kCGImagePropertyIPTCCity");
const CFStringRef kCGImagePropertyIPTCSubLocation = static_cast<CFStringRef>(@"kCGImagePropertyIPTCSubLocation");
const CFStringRef kCGImagePropertyIPTCProvinceState = static_cast<CFStringRef>(@"kCGImagePropertyIPTCProvinceState");
const CFStringRef kCGImagePropertyIPTCCountryPrimaryLocationCode =
    static_cast<CFStringRef>(@"kCGImagePropertyIPTCCountryPrimaryLocationCode");
const CFStringRef kCGImagePropertyIPTCCountryPrimaryLocationName =
    static_cast<CFStringRef>(@"kCGImagePropertyIPTCCountryPrimaryLocationName");
const CFStringRef kCGImagePropertyIPTCOriginalTransmissionReference =
    static_cast<CFStringRef>(@"kCGImagePropertyIPTCCountryPrimaryLocationName");
const CFStringRef kCGImagePropertyIPTCHeadline = static_cast<CFStringRef>(@"kCGImagePropertyIPTCHeadline");
const CFStringRef kCGImagePropertyIPTCCredit = static_cast<CFStringRef>(@"kCGImagePropertyIPTCHeadline");
const CFStringRef kCGImagePropertyIPTCSource = static_cast<CFStringRef>(@"kCGImagePropertyIPTCSource");
const CFStringRef kCGImagePropertyIPTCCopyrightNotice = static_cast<CFStringRef>(@"kCGImagePropertyIPTCCopyrightNotice");
const CFStringRef kCGImagePropertyIPTCContact = static_cast<CFStringRef>(@"kCGImagePropertyIPTCContact");
const CFStringRef kCGImagePropertyIPTCCaptionAbstract = static_cast<CFStringRef>(@"kCGImagePropertyIPTCCaptionAbstract");
const CFStringRef kCGImagePropertyIPTCWriterEditor = static_cast<CFStringRef>(@"kCGImagePropertyIPTCWriterEditor");
const CFStringRef kCGImagePropertyIPTCImageType = static_cast<CFStringRef>(@"kCGImagePropertyIPTCImageType");
const CFStringRef kCGImagePropertyIPTCImageOrientation = static_cast<CFStringRef>(@"kCGImagePropertyIPTCImageOrientation");
const CFStringRef kCGImagePropertyIPTCLanguageIdentifier = static_cast<CFStringRef>(@"kCGImagePropertyIPTCLanguageIdentifier");
const CFStringRef kCGImagePropertyIPTCStarRating = static_cast<CFStringRef>(@"");
const CFStringRef kCGImagePropertyIPTCCreatorContactInfo = static_cast<CFStringRef>(@"kCGImagePropertyIPTCCreatorContactInfo");
const CFStringRef kCGImagePropertyIPTCRightsUsageTerms = static_cast<CFStringRef>(@"kCGImagePropertyIPTCRightsUsageTerms");
const CFStringRef kCGImagePropertyIPTCScene = static_cast<CFStringRef>(@"kCGImagePropertyIPTCScene");
const CFStringRef kCGImagePropertyIPTCContactInfoCity = static_cast<CFStringRef>(@"");
const CFStringRef kCGImagePropertyIPTCContactInfoCountry = static_cast<CFStringRef>(@"");
const CFStringRef kCGImagePropertyIPTCContactInfoAddress = static_cast<CFStringRef>(@"kCGImagePropertyIPTCContactInfoAddress");
const CFStringRef kCGImagePropertyIPTCContactInfoPostalCode = static_cast<CFStringRef>(@"");
const CFStringRef kCGImagePropertyIPTCContactInfoStateProvince = static_cast<CFStringRef>(@"kCGImagePropertyIPTCContactInfoStateProvince");
const CFStringRef kCGImagePropertyIPTCContactInfoEmails = static_cast<CFStringRef>(@"kCGImagePropertyIPTCContactInfoEmails");
const CFStringRef kCGImagePropertyIPTCContactInfoPhones = static_cast<CFStringRef>(@"kCGImagePropertyIPTCContactInfoPhones");
const CFStringRef kCGImagePropertyIPTCContactInfoWebURLs = static_cast<CFStringRef>(@"kCGImagePropertyIPTCContactInfoWebURLs");
const CFStringRef kCGImagePropertyJFIFVersion = static_cast<CFStringRef>(@"Version");
const CFStringRef kCGImagePropertyJFIFXDensity = static_cast<CFStringRef>(@"XDensity");
const CFStringRef kCGImagePropertyJFIFYDensity = static_cast<CFStringRef>(@"YDensity");
const CFStringRef kCGImagePropertyJFIFDensityUnit = static_cast<CFStringRef>(@"DensityUnit");
const CFStringRef kCGImagePropertyJFIFIsProgressive = static_cast<CFStringRef>(@"IsProgressive");
const CFStringRef kCGImagePropertyPNGGamma = static_cast<CFStringRef>(@"Gamma");
const CFStringRef kCGImagePropertyPNGInterlaceType = static_cast<CFStringRef>(@"InterlaceType");
const CFStringRef kCGImagePropertyPNGXPixelsPerMeter = static_cast<CFStringRef>(@"XPixelsPerMeter");
const CFStringRef kCGImagePropertyPNGYPixelsPerMeter = static_cast<CFStringRef>(@"YPixelsPerMeter");
const CFStringRef kCGImagePropertyPNGsRGBIntent = static_cast<CFStringRef>(@"sRGBIntent");
const CFStringRef kCGImagePropertyPNGChromaticities = static_cast<CFStringRef>(@"Chromaticities");
const CFStringRef kCGImagePropertyPNGAuthor = static_cast<CFStringRef>(@"Author");
const CFStringRef kCGImagePropertyPNGCopyright = static_cast<CFStringRef>(@"Copyright");
const CFStringRef kCGImagePropertyPNGCreationTime = static_cast<CFStringRef>(@"CreationTime");
const CFStringRef kCGImagePropertyPNGDescription = static_cast<CFStringRef>(@"Description");
const CFStringRef kCGImagePropertyPNGModificationTime = static_cast<CFStringRef>(@"ModificationTime");
const CFStringRef kCGImagePropertyPNGSoftware = static_cast<CFStringRef>(@"Software");
const CFStringRef kCGImagePropertyPNGTitle = static_cast<CFStringRef>(@"Title");
const CFStringRef kCGImagePropertyTIFFCompression = static_cast<CFStringRef>(@"Compression");
const CFStringRef kCGImagePropertyTIFFPhotometricInterpretation =
    static_cast<CFStringRef>(@"PhotometricInterpretation");
const CFStringRef kCGImagePropertyTIFFDocumentName = static_cast<CFStringRef>(@"DocumentName");
const CFStringRef kCGImagePropertyTIFFImageDescription = static_cast<CFStringRef>(@"ImageDescription");
const CFStringRef kCGImagePropertyTIFFMake = static_cast<CFStringRef>(@"Make");
const CFStringRef kCGImagePropertyTIFFModel = static_cast<CFStringRef>(@"Model");
const CFStringRef kCGImagePropertyTIFFOrientation = static_cast<CFStringRef>(@"Orientation");
const CFStringRef kCGImagePropertyTIFFXResolution = static_cast<CFStringRef>(@"XResolution");
const CFStringRef kCGImagePropertyTIFFYResolution = static_cast<CFStringRef>(@"YResolution");
const CFStringRef kCGImagePropertyTIFFResolutionUnit = static_cast<CFStringRef>(@"ResolutionUnit");
const CFStringRef kCGImagePropertyTIFFSoftware = static_cast<CFStringRef>(@"Software");
const CFStringRef kCGImagePropertyTIFFTransferFunction = static_cast<CFStringRef>(@"TransferFunction");
const CFStringRef kCGImagePropertyTIFFDateTime = static_cast<CFStringRef>(@"DateTime");
const CFStringRef kCGImagePropertyTIFFArtist = static_cast<CFStringRef>(@"Artist");
const CFStringRef kCGImagePropertyTIFFHostComputer = static_cast<CFStringRef>(@"HostComputer");
const CFStringRef kCGImagePropertyTIFFCopyright = static_cast<CFStringRef>(@"Copyright");
const CFStringRef kCGImagePropertyTIFFWhitePoint = static_cast<CFStringRef>(@"WhitePoint");
const CFStringRef kCGImagePropertyTIFFPrimaryChromaticities = static_cast<CFStringRef>(@"PrimaryChromaticities");
const CFStringRef kCGImagePropertyDNGVersion = static_cast<CFStringRef>(@"kCGImagePropertyDNGVersion");
const CFStringRef kCGImagePropertyDNGBackwardVersion = static_cast<CFStringRef>(@"kCGImagePropertyDNGBackwardVersion");
const CFStringRef kCGImagePropertyDNGUniqueCameraModel = static_cast<CFStringRef>(@"kCGImagePropertyDNGUniqueCameraModel");
const CFStringRef kCGImagePropertyDNGLocalizedCameraModel = static_cast<CFStringRef>(@"kCGImagePropertyDNGLocalizedCameraModel");
const CFStringRef kCGImagePropertyDNGCameraSerialNumber = static_cast<CFStringRef>(@"kCGImagePropertyDNGCameraSerialNumber");
const CFStringRef kCGImagePropertyDNGLensInfo = static_cast<CFStringRef>(@"kCGImagePropertyDNGLensInfo");
const CFStringRef kCGImageProperty8BIMLayerNames = static_cast<CFStringRef>(@"kCGImageProperty8BIMLayerNames");
const CFStringRef kCGImagePropertyCIFFDescription = static_cast<CFStringRef>(@"kCGImagePropertyCIFFDescription");
const CFStringRef kCGImagePropertyCIFFFirmware = static_cast<CFStringRef>(@"kCGImagePropertyCIFFFirmware");
const CFStringRef kCGImagePropertyCIFFOwnerName = static_cast<CFStringRef>(@"kCGImagePropertyCIFFOwnerName");
const CFStringRef kCGImagePropertyCIFFImageName = static_cast<CFStringRef>(@"kCGImagePropertyCIFFImageName");
const CFStringRef kCGImagePropertyCIFFImageFileName = static_cast<CFStringRef>(@"kCGImagePropertyCIFFImageFileName");
const CFStringRef kCGImagePropertyCIFFReleaseMethod = static_cast<CFStringRef>(@"kCGImagePropertyCIFFReleaseMethod");
const CFStringRef kCGImagePropertyCIFFReleaseTiming = static_cast<CFStringRef>(@"kCGImagePropertyCIFFReleaseTiming");
const CFStringRef kCGImagePropertyCIFFRecordID = static_cast<CFStringRef>(@"kCGImagePropertyCIFFReleaseTiming");
const CFStringRef kCGImagePropertyCIFFSelfTimingTime = static_cast<CFStringRef>(@"kCGImagePropertyCIFFReleaseTiming");
const CFStringRef kCGImagePropertyCIFFCameraSerialNumber = static_cast<CFStringRef>(@"kCGImagePropertyCIFFCameraSerialNumber");
const CFStringRef kCGImagePropertyCIFFImageSerialNumber = static_cast<CFStringRef>(@"kCGImagePropertyCIFFImageSerialNumber");
const CFStringRef kCGImagePropertyCIFFContinuousDrive = static_cast<CFStringRef>(@"kCGImagePropertyCIFFContinuousDrive");
const CFStringRef kCGImagePropertyCIFFFocusMode = static_cast<CFStringRef>(@"kCGImagePropertyCIFFFocusMode");
const CFStringRef kCGImagePropertyCIFFMeteringMode = static_cast<CFStringRef>(@"kCGImagePropertyCIFFMeteringMode");
const CFStringRef kCGImagePropertyCIFFShootingMode = static_cast<CFStringRef>(@"kCGImagePropertyCIFFShootingMode");
const CFStringRef kCGImagePropertyCIFFLensMaxMM = static_cast<CFStringRef>(@"kCGImagePropertyCIFFLensMaxMM");
const CFStringRef kCGImagePropertyCIFFLensMinMM = static_cast<CFStringRef>(@"kCGImagePropertyCIFFLensMinMM");
const CFStringRef kCGImagePropertyCIFFLensModel = static_cast<CFStringRef>(@"kCGImagePropertyCIFFLensModel");
const CFStringRef kCGImagePropertyCIFFWhiteBalanceIndex = static_cast<CFStringRef>(@"kCGImagePropertyCIFFWhiteBalanceIndex");
const CFStringRef kCGImagePropertyCIFFFlashExposureComp = static_cast<CFStringRef>(@"");
const CFStringRef kCGImagePropertyCIFFMeasuredEV = static_cast<CFStringRef>(@"kCGImagePropertyCIFFMeasuredEV");
const CFStringRef kCGImagePropertyMakerNikonISOSetting = static_cast<CFStringRef>(@"kCGImagePropertyMakerNikonISOSetting");
const CFStringRef kCGImagePropertyMakerNikonColorMode = static_cast<CFStringRef>(@"kCGImagePropertyMakerNikonColorMode");
const CFStringRef kCGImagePropertyMakerNikonQuality = static_cast<CFStringRef>(@"kCGImagePropertyMakerNikonQuality");
const CFStringRef kCGImagePropertyMakerNikonWhiteBalanceMode = static_cast<CFStringRef>(@"kCGImagePropertyMakerNikonWhiteBalanceMode");
const CFStringRef kCGImagePropertyMakerNikonSharpenMode = static_cast<CFStringRef>(@"");
const CFStringRef kCGImagePropertyMakerNikonFocusMode = static_cast<CFStringRef>(@"kCGImagePropertyMakerNikonFocusMode");
const CFStringRef kCGImagePropertyMakerNikonFlashSetting = static_cast<CFStringRef>(@"kCGImagePropertyMakerNikonFlashSetting");
const CFStringRef kCGImagePropertyMakerNikonISOSelection = static_cast<CFStringRef>(@"kCGImagePropertyMakerNikonISOSelection");
const CFStringRef kCGImagePropertyMakerNikonFlashExposureComp = static_cast<CFStringRef>(@"kCGImagePropertyMakerNikonFlashExposureComp");
const CFStringRef kCGImagePropertyMakerNikonImageAdjustment = static_cast<CFStringRef>(@"kCGImagePropertyMakerNikonImageAdjustment");
const CFStringRef kCGImagePropertyMakerNikonLensAdapter = static_cast<CFStringRef>(@"kCGImagePropertyMakerNikonLensAdapter");
const CFStringRef kCGImagePropertyMakerNikonLensType = static_cast<CFStringRef>(@"kCGImagePropertyMakerNikonLensType");
const CFStringRef kCGImagePropertyMakerNikonLensInfo = static_cast<CFStringRef>(@"kCGImagePropertyMakerNikonLensInfo");
const CFStringRef kCGImagePropertyMakerNikonFocusDistance = static_cast<CFStringRef>(@"kCGImagePropertyMakerNikonFocusDistance");
const CFStringRef kCGImagePropertyMakerNikonDigitalZoom = static_cast<CFStringRef>(@"kCGImagePropertyMakerNikonDigitalZoom");
const CFStringRef kCGImagePropertyMakerNikonShootingMode = static_cast<CFStringRef>(@"kCGImagePropertyMakerNikonShootingMode");
const CFStringRef kCGImagePropertyMakerNikonShutterCount = static_cast<CFStringRef>(@"kCGImagePropertyMakerNikonShutterCount");
const CFStringRef kCGImagePropertyMakerNikonCameraSerialNumber = static_cast<CFStringRef>(@"kCGImagePropertyMakerNikonCameraSerialNumber");
const CFStringRef kCGImagePropertyMakerCanonOwnerName = static_cast<CFStringRef>(@"kCGImagePropertyMakerCanonOwnerName");
const CFStringRef kCGImagePropertyMakerCanonCameraSerialNumber = static_cast<CFStringRef>(@"kCGImagePropertyMakerCanonCameraSerialNumber");
const CFStringRef kCGImagePropertyMakerCanonImageSerialNumber = static_cast<CFStringRef>(@"kCGImagePropertyMakerCanonImageSerialNumber");
const CFStringRef kCGImagePropertyMakerCanonFlashExposureComp = static_cast<CFStringRef>(@"kCGImagePropertyMakerCanonFlashExposureComp");
const CFStringRef kCGImagePropertyMakerCanonContinuousDrive = static_cast<CFStringRef>(@"kCGImagePropertyMakerCanonContinuousDrive");
const CFStringRef kCGImagePropertyMakerCanonLensModel = static_cast<CFStringRef>(@"kCGImagePropertyMakerCanonLensModel");
const CFStringRef kCGImagePropertyMakerCanonFirmware = static_cast<CFStringRef>(@"kCGImagePropertyMakerCanonFirmware");
const CFStringRef kCGImagePropertyMakerCanonAspectRatioInfo = static_cast<CFStringRef>(@"kCGImagePropertyMakerCanonAspectRatioInfo");
