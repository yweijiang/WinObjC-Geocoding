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

const CFStringRef kCGImagePropertyTIFFDictionary = static_cast<CFStringRef>(@"TIFF");
const CFStringRef kCGImagePropertyGIFDictionary = static_cast<CFStringRef>(@"GIF");
const CFStringRef kCGImagePropertyJFIFDictionary = static_cast<CFStringRef>(@"JFIF");
const CFStringRef kCGImagePropertyExifDictionary = static_cast<CFStringRef>(@"Exif");
const CFStringRef kCGImagePropertyPNGDictionary = static_cast<CFStringRef>(@"PNG");
const CFStringRef kCGImagePropertyIPTCDictionary = static_cast<CFStringRef>(@"IPTC");
const CFStringRef kCGImagePropertyGPSDictionary = static_cast<CFStringRef>(@"GPS");
const CFStringRef kCGImagePropertyRawDictionary = static_cast<CFStringRef>(@"RawDictionary");
const CFStringRef kCGImagePropertyCIFFDictionary = static_cast<CFStringRef>(@"CIFF");
const CFStringRef kCGImageProperty8BIMDictionary = static_cast<CFStringRef>(@"8BIM");
const CFStringRef kCGImagePropertyDNGDictionary = static_cast<CFStringRef>(@"DNG");
const CFStringRef kCGImagePropertyExifAuxDictionary = static_cast<CFStringRef>(@"Aux");
const CFStringRef kCGImagePropertyMakerCanonDictionary = static_cast<CFStringRef>(@"");
const CFStringRef kCGImagePropertyMakerNikonDictionary = static_cast<CFStringRef>(@"");
const CFStringRef kCGImagePropertyMakerMinoltaDictionary = static_cast<CFStringRef>(@"Minolta");
const CFStringRef kCGImagePropertyMakerFujiDictionary = static_cast<CFStringRef>(@"Fuji");
const CFStringRef kCGImagePropertyMakerOlympusDictionary = static_cast<CFStringRef>(@"Olympus");
const CFStringRef kCGImagePropertyMakerPentaxDictionary = static_cast<CFStringRef>(@"Pentax");
const CFStringRef kCGImagePropertyFileSize = static_cast<CFStringRef>(@"FileSize");
const CFStringRef kCGImagePropertyDPIWidth = static_cast<CFStringRef>(@"DPIWidth");
const CFStringRef kCGImagePropertyDPIHeight = static_cast<CFStringRef>(@"DPIHeight");
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
const CFStringRef kCGImagePropertyExifExposureTime = static_cast<CFStringRef>(@"ExposureTime");
const CFStringRef kCGImagePropertyExifFNumber = static_cast<CFStringRef>(@"FNumber");
const CFStringRef kCGImagePropertyExifExposureProgram = static_cast<CFStringRef>(@"ExposureProgram");
const CFStringRef kCGImagePropertyExifSpectralSensitivity = static_cast<CFStringRef>(@"SpectralSensitivity");
const CFStringRef kCGImagePropertyExifISOSpeedRatings = static_cast<CFStringRef>(@"ISOSpeedRatings");
const CFStringRef kCGImagePropertyExifOECF = static_cast<CFStringRef>(@"OECF");
const CFStringRef kCGImagePropertyExifVersion = static_cast<CFStringRef>(@"Version");
const CFStringRef kCGImagePropertyExifDateTimeOriginal = static_cast<CFStringRef>(@"DateTimeOriginal");
const CFStringRef kCGImagePropertyExifDateTimeDigitized = static_cast<CFStringRef>(@"DateTimeDigitized");
const CFStringRef kCGImagePropertyExifComponentsConfiguration = static_cast<CFStringRef>(@"ComponentsConfiguration");
const CFStringRef kCGImagePropertyExifCompressedBitsPerPixel = static_cast<CFStringRef>(@"CompressedBitsPerPixel");
const CFStringRef kCGImagePropertyExifShutterSpeedValue = static_cast<CFStringRef>(@"ShutterSpeedValue");
const CFStringRef kCGImagePropertyExifApertureValue = static_cast<CFStringRef>(@"ApertureValue");
const CFStringRef kCGImagePropertyExifBrightnessValue = static_cast<CFStringRef>(@"BrightnessValue");
const CFStringRef kCGImagePropertyExifExposureBiasValue = static_cast<CFStringRef>(@"ExposureBiasValue");
const CFStringRef kCGImagePropertyExifMaxApertureValue = static_cast<CFStringRef>(@"MaxApertureValue");
const CFStringRef kCGImagePropertyExifSubjectDistance = static_cast<CFStringRef>(@"SubjectDistance");
const CFStringRef kCGImagePropertyExifMeteringMode = static_cast<CFStringRef>(@"MeteringMode");
const CFStringRef kCGImagePropertyExifLightSource = static_cast<CFStringRef>(@"LightSource");
const CFStringRef kCGImagePropertyExifFlash = static_cast<CFStringRef>(@"Flash");
const CFStringRef kCGImagePropertyExifFocalLength = static_cast<CFStringRef>(@"FocalLength");
const CFStringRef kCGImagePropertyExifSubjectArea = static_cast<CFStringRef>(@"SubjectArea");
const CFStringRef kCGImagePropertyExifMakerNote = static_cast<CFStringRef>(@"MakerNote");
const CFStringRef kCGImagePropertyExifUserComment = static_cast<CFStringRef>(@"UserComment");
const CFStringRef kCGImagePropertyExifSubsecTime = static_cast<CFStringRef>(@"SubsecTime");
const CFStringRef kCGImagePropertyExifSubsecTimeOrginal = static_cast<CFStringRef>(@"SubsecTimeOrginal");
const CFStringRef kCGImagePropertyExifSubsecTimeDigitized = static_cast<CFStringRef>(@"SubsecTimeDigitized");
const CFStringRef kCGImagePropertyExifFlashPixVersion = static_cast<CFStringRef>(@"FlashPixVersion");
const CFStringRef kCGImagePropertyExifColorSpace = static_cast<CFStringRef>(@"ColorSpace");
const CFStringRef kCGImagePropertyExifPixelXDimension = static_cast<CFStringRef>(@"PixelXDimension");
const CFStringRef kCGImagePropertyExifPixelYDimension = static_cast<CFStringRef>(@"PixelYDimension");
const CFStringRef kCGImagePropertyExifRelatedSoundFile = static_cast<CFStringRef>(@"RelatedSoundFile");
const CFStringRef kCGImagePropertyExifFlashEnergy = static_cast<CFStringRef>(@"FlashEnergy");
const CFStringRef kCGImagePropertyExifSpatialFrequencyResponse = static_cast<CFStringRef>(@"SpatialFrequencyResponse");
const CFStringRef kCGImagePropertyExifFocalPlaneXResolution = static_cast<CFStringRef>(@"FocalPlaneXResolution");
const CFStringRef kCGImagePropertyExifFocalPlaneYResolution = static_cast<CFStringRef>(@"FocalPlaneYResolution");
const CFStringRef kCGImagePropertyExifFocalPlaneResolutionUnit = static_cast<CFStringRef>(@"FocalPlaneResolutionUnit");
const CFStringRef kCGImagePropertyExifSubjectLocation = static_cast<CFStringRef>(@"SubjectLocation");
const CFStringRef kCGImagePropertyExifExposureIndex = static_cast<CFStringRef>(@"ExposureIndex");
const CFStringRef kCGImagePropertyExifSensingMethod = static_cast<CFStringRef>(@"SensingMethod");
const CFStringRef kCGImagePropertyExifFileSource = static_cast<CFStringRef>(@"FileSource");
const CFStringRef kCGImagePropertyExifSceneType = static_cast<CFStringRef>(@"SceneType");
const CFStringRef kCGImagePropertyExifCFAPattern = static_cast<CFStringRef>(@"CFAPattern");
const CFStringRef kCGImagePropertyExifCustomRendered = static_cast<CFStringRef>(@"CustomRendered");
const CFStringRef kCGImagePropertyExifExposureMode = static_cast<CFStringRef>(@"ExposureMode");
const CFStringRef kCGImagePropertyExifWhiteBalance = static_cast<CFStringRef>(@"WhiteBalance");
const CFStringRef kCGImagePropertyExifDigitalZoomRatio = static_cast<CFStringRef>(@"DigitalZoomRatio");
const CFStringRef kCGImagePropertyExifFocalLenIn35mmFilm = static_cast<CFStringRef>(@"FocalLenIn35mmFilm");
const CFStringRef kCGImagePropertyExifSceneCaptureType = static_cast<CFStringRef>(@"SceneCaptureType");
const CFStringRef kCGImagePropertyExifGainControl = static_cast<CFStringRef>(@"GainControl");
const CFStringRef kCGImagePropertyExifContrast = static_cast<CFStringRef>(@"Contrast");
const CFStringRef kCGImagePropertyExifSaturation = static_cast<CFStringRef>(@"Saturation");
const CFStringRef kCGImagePropertyExifSharpness = static_cast<CFStringRef>(@"Sharpness");
const CFStringRef kCGImagePropertyExifDeviceSettingDescription = static_cast<CFStringRef>(@"DeviceSettingDescription");
const CFStringRef kCGImagePropertyExifSubjectDistRange = static_cast<CFStringRef>(@"SubjectDistRange");
const CFStringRef kCGImagePropertyExifImageUniqueID = static_cast<CFStringRef>(@"ImageUniqueID");
const CFStringRef kCGImagePropertyExifGamma = static_cast<CFStringRef>(@"Gamma");
const CFStringRef kCGImagePropertyExifCameraOwnerName = static_cast<CFStringRef>(@"CameraOwnerName");
const CFStringRef kCGImagePropertyExifBodySerialNumber = static_cast<CFStringRef>(@"BodySerialNumber");
const CFStringRef kCGImagePropertyExifLensSpecification = static_cast<CFStringRef>(@"LensSpecification");
const CFStringRef kCGImagePropertyExifLensMake = static_cast<CFStringRef>(@"LensMake");
const CFStringRef kCGImagePropertyExifLensModel = static_cast<CFStringRef>(@"LensModel");
const CFStringRef kCGImagePropertyExifLensSerialNumber = static_cast<CFStringRef>(@"LensSerialNumber");
const CFStringRef kCGImagePropertyExifAuxLensInfo = static_cast<CFStringRef>(@"AuxLensInfo");
const CFStringRef kCGImagePropertyExifAuxLensModel = static_cast<CFStringRef>(@"AuxLensModel");
const CFStringRef kCGImagePropertyExifAuxSerialNumber = static_cast<CFStringRef>(@"AuxSerialNumber");
const CFStringRef kCGImagePropertyExifAuxLensID = static_cast<CFStringRef>(@"AuxLensID");
const CFStringRef kCGImagePropertyExifAuxLensSerialNumber = static_cast<CFStringRef>(@"AuxLensSerialNumber");
const CFStringRef kCGImagePropertyExifAuxImageNumber = static_cast<CFStringRef>(@"AuxImageNumber");
const CFStringRef kCGImagePropertyExifAuxFlashCompensation = static_cast<CFStringRef>(@"AuxFlashCompensation");
const CFStringRef kCGImagePropertyExifAuxOwnerName = static_cast<CFStringRef>(@"AuxOwnerName");
const CFStringRef kCGImagePropertyExifAuxFirmware = static_cast<CFStringRef>(@"AuxFirmware");
const CFStringRef kCGImagePropertyGIFLoopCount = static_cast<CFStringRef>(@"LoopCount");
const CFStringRef kCGImagePropertyGIFDelayTime = static_cast<CFStringRef>(@"DelayTime");
const CFStringRef kCGImagePropertyGIFImageColorMap = static_cast<CFStringRef>(@"ImageColorMap");
const CFStringRef kCGImagePropertyGIFHasGlobalColorMap = static_cast<CFStringRef>(@"HasGlobalColorMap");
const CFStringRef kCGImagePropertyGIFUnclampedDelayTime = static_cast<CFStringRef>(@"UnclampedDelayTime");
const CFStringRef kCGImagePropertyGPSVersion = static_cast<CFStringRef>(@"Version");
const CFStringRef kCGImagePropertyGPSLatitudeRef = static_cast<CFStringRef>(@"LatitudeRef");
const CFStringRef kCGImagePropertyGPSLatitude = static_cast<CFStringRef>(@"Latitude");
const CFStringRef kCGImagePropertyGPSLongitudeRef = static_cast<CFStringRef>(@"LongitudeRef");
const CFStringRef kCGImagePropertyGPSLongitude = static_cast<CFStringRef>(@"Longitude");
const CFStringRef kCGImagePropertyGPSAltitudeRef = static_cast<CFStringRef>(@"AltitudeRef");
const CFStringRef kCGImagePropertyGPSAltitude = static_cast<CFStringRef>(@"Altitude");
const CFStringRef kCGImagePropertyGPSTimeStamp = static_cast<CFStringRef>(@"TimeStamp");
const CFStringRef kCGImagePropertyGPSSatellites = static_cast<CFStringRef>(@"Satellites");
const CFStringRef kCGImagePropertyGPSStatus = static_cast<CFStringRef>(@"GPSStatus");
const CFStringRef kCGImagePropertyGPSMeasureMode = static_cast<CFStringRef>(@"MeasureMode");
const CFStringRef kCGImagePropertyGPSDOP = static_cast<CFStringRef>(@"DOP");
const CFStringRef kCGImagePropertyGPSSpeedRef = static_cast<CFStringRef>(@"SpeedRef");
const CFStringRef kCGImagePropertyGPSSpeed = static_cast<CFStringRef>(@"Speed");
const CFStringRef kCGImagePropertyGPSTrackRef = static_cast<CFStringRef>(@"TrackRef");
const CFStringRef kCGImagePropertyGPSTrack = static_cast<CFStringRef>(@"Track");
const CFStringRef kCGImagePropertyGPSImgDirectionRef = static_cast<CFStringRef>(@"ImgDirectionRef");
const CFStringRef kCGImagePropertyGPSImgDirection = static_cast<CFStringRef>(@"ImgDirection");
const CFStringRef kCGImagePropertyGPSMapDatum = static_cast<CFStringRef>(@"MapDatum");
const CFStringRef kCGImagePropertyGPSDestLatitudeRef = static_cast<CFStringRef>(@"DestLatitudeRef");
const CFStringRef kCGImagePropertyGPSDestLatitude = static_cast<CFStringRef>(@"DestLatitude");
const CFStringRef kCGImagePropertyGPSDestLongitudeRef = static_cast<CFStringRef>(@"DestLongitudeRef");
const CFStringRef kCGImagePropertyGPSDestLongitude = static_cast<CFStringRef>(@"DestLongitude");
const CFStringRef kCGImagePropertyGPSDestBearingRef = static_cast<CFStringRef>(@"DestBearingRef");
const CFStringRef kCGImagePropertyGPSDestBearing = static_cast<CFStringRef>(@"DestBearing");
const CFStringRef kCGImagePropertyGPSDestDistanceRef = static_cast<CFStringRef>(@"DestDistanceRef");
const CFStringRef kCGImagePropertyGPSDestDistance = static_cast<CFStringRef>(@"DestDistance");
const CFStringRef kCGImagePropertyGPSProcessingMethod = static_cast<CFStringRef>(@"ProcessingMethod");
const CFStringRef kCGImagePropertyGPSAreaInformation = static_cast<CFStringRef>(@"AreaInformation");
const CFStringRef kCGImagePropertyGPSDateStamp = static_cast<CFStringRef>(@"DateStamp");
const CFStringRef kCGImagePropertyGPSDifferental = static_cast<CFStringRef>(@"Differental");
const CFStringRef kCGImagePropertyIPTCObjectTypeReference = static_cast<CFStringRef>(@"ObjectTypeReference");
const CFStringRef kCGImagePropertyIPTCObjectAttributeReference = static_cast<CFStringRef>(@"ObjectAttributeReference");
const CFStringRef kCGImagePropertyIPTCObjectName = static_cast<CFStringRef>(@"ObjectName");
const CFStringRef kCGImagePropertyIPTCEditStatus = static_cast<CFStringRef>(@"EditStatus");
const CFStringRef kCGImagePropertyIPTCEditorialUpdate = static_cast<CFStringRef>(@"EditorialUpdate");
const CFStringRef kCGImagePropertyIPTCUrgency = static_cast<CFStringRef>(@"Urgency");
const CFStringRef kCGImagePropertyIPTCSubjectReference = static_cast<CFStringRef>(@"SubjectReference");
const CFStringRef kCGImagePropertyIPTCCategory = static_cast<CFStringRef>(@"Category");
const CFStringRef kCGImagePropertyIPTCSupplementalCategory = static_cast<CFStringRef>(@"SupplementalCategory");
const CFStringRef kCGImagePropertyIPTCFixtureIdentifier = static_cast<CFStringRef>(@"FixtureIdentifier");
const CFStringRef kCGImagePropertyIPTCKeywords = static_cast<CFStringRef>(@"Keywords");
const CFStringRef kCGImagePropertyIPTCContentLocationCode = static_cast<CFStringRef>(@"ContentLocationCode");
const CFStringRef kCGImagePropertyIPTCContentLocationName = static_cast<CFStringRef>(@"ContentLocationName");
const CFStringRef kCGImagePropertyIPTCReleaseDate = static_cast<CFStringRef>(@"ReleaseDate");
const CFStringRef kCGImagePropertyIPTCReleaseTime = static_cast<CFStringRef>(@"ReleaseTime");
const CFStringRef kCGImagePropertyIPTCExpirationDate = static_cast<CFStringRef>(@"ExpirationDate");
const CFStringRef kCGImagePropertyIPTCExpirationTime = static_cast<CFStringRef>(@"ExpirationTime");
const CFStringRef kCGImagePropertyIPTCSpecialInstructions = static_cast<CFStringRef>(@"SpecialInstructions");
const CFStringRef kCGImagePropertyIPTCActionAdvised = static_cast<CFStringRef>(@"ActionAdvised");
const CFStringRef kCGImagePropertyIPTCReferenceService = static_cast<CFStringRef>(@"ReferenceService");
const CFStringRef kCGImagePropertyIPTCReferenceDate = static_cast<CFStringRef>(@"ReferenceDate");
const CFStringRef kCGImagePropertyIPTCReferenceNumber = static_cast<CFStringRef>(@"ReferenceNumber");
const CFStringRef kCGImagePropertyIPTCDateCreated = static_cast<CFStringRef>(@"DateCreated");
const CFStringRef kCGImagePropertyIPTCTimeCreated = static_cast<CFStringRef>(@"TimeCreated");
const CFStringRef kCGImagePropertyIPTCDigitalCreationDate = static_cast<CFStringRef>(@"DigitalCreationDate");
const CFStringRef kCGImagePropertyIPTCDigitalCreationTime = static_cast<CFStringRef>(@"DigitalCreationTime");
const CFStringRef kCGImagePropertyIPTCOriginatingProgram = static_cast<CFStringRef>(@"OriginatingProgram");
const CFStringRef kCGImagePropertyIPTCProgramVersion = static_cast<CFStringRef>(@"ProgramVersion");
const CFStringRef kCGImagePropertyIPTCObjectCycle = static_cast<CFStringRef>(@"ObjectCycle");
const CFStringRef kCGImagePropertyIPTCByline = static_cast<CFStringRef>(@"Byline");
const CFStringRef kCGImagePropertyIPTCBylineTitle = static_cast<CFStringRef>(@"BylineTitle");
const CFStringRef kCGImagePropertyIPTCCity = static_cast<CFStringRef>(@"City");
const CFStringRef kCGImagePropertyIPTCSubLocation = static_cast<CFStringRef>(@"SubLocation");
const CFStringRef kCGImagePropertyIPTCProvinceState = static_cast<CFStringRef>(@"ProvinceState");
const CFStringRef kCGImagePropertyIPTCCountryPrimaryLocationCode = static_cast<CFStringRef>(@"CountryPrimaryLocationCode");
const CFStringRef kCGImagePropertyIPTCCountryPrimaryLocationName = static_cast<CFStringRef>(@"CountryPrimaryLocationName");
const CFStringRef kCGImagePropertyIPTCOriginalTransmissionReference = static_cast<CFStringRef>(@"OriginalTransmissionReference");
const CFStringRef kCGImagePropertyIPTCHeadline = static_cast<CFStringRef>(@"Headline");
const CFStringRef kCGImagePropertyIPTCCredit = static_cast<CFStringRef>(@"Credit");
const CFStringRef kCGImagePropertyIPTCSource = static_cast<CFStringRef>(@"Source");
const CFStringRef kCGImagePropertyIPTCCopyrightNotice = static_cast<CFStringRef>(@"CopyrightNotice");
const CFStringRef kCGImagePropertyIPTCContact = static_cast<CFStringRef>(@"Contact");
const CFStringRef kCGImagePropertyIPTCCaptionAbstract = static_cast<CFStringRef>(@"CaptionAbstract");
const CFStringRef kCGImagePropertyIPTCWriterEditor = static_cast<CFStringRef>(@"WriterEditor");
const CFStringRef kCGImagePropertyIPTCImageType = static_cast<CFStringRef>(@"ImageType");
const CFStringRef kCGImagePropertyIPTCImageOrientation = static_cast<CFStringRef>(@"ImageOrientation");
const CFStringRef kCGImagePropertyIPTCLanguageIdentifier = static_cast<CFStringRef>(@"LanguageIdentifier");
const CFStringRef kCGImagePropertyIPTCStarRating = static_cast<CFStringRef>(@"StarRating");
const CFStringRef kCGImagePropertyIPTCCreatorContactInfo = static_cast<CFStringRef>(@"CreatorContactInfo");
const CFStringRef kCGImagePropertyIPTCRightsUsageTerms = static_cast<CFStringRef>(@"RightsUsageTerms");
const CFStringRef kCGImagePropertyIPTCScene = static_cast<CFStringRef>(@"Scene");
const CFStringRef kCGImagePropertyIPTCContactInfoCity = static_cast<CFStringRef>(@"ContactInfoCity");
const CFStringRef kCGImagePropertyIPTCContactInfoCountry = static_cast<CFStringRef>(@"ContactInfoCountry");
const CFStringRef kCGImagePropertyIPTCContactInfoAddress = static_cast<CFStringRef>(@"ContactInfoAddress");
const CFStringRef kCGImagePropertyIPTCContactInfoPostalCode = static_cast<CFStringRef>(@"ContactInfoPostalCode");
const CFStringRef kCGImagePropertyIPTCContactInfoStateProvince = static_cast<CFStringRef>(@"ContactInfoStateProvince");
const CFStringRef kCGImagePropertyIPTCContactInfoEmails = static_cast<CFStringRef>(@"ContactInfoEmails");
const CFStringRef kCGImagePropertyIPTCContactInfoPhones = static_cast<CFStringRef>(@"ContactInfoPhones");
const CFStringRef kCGImagePropertyIPTCContactInfoWebURLs = static_cast<CFStringRef>(@"ContactInfoWebURLs");
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
const CFStringRef kCGImagePropertyDNGVersion = static_cast<CFStringRef>(@"Version");
const CFStringRef kCGImagePropertyDNGBackwardVersion = static_cast<CFStringRef>(@"BackwardVersion");
const CFStringRef kCGImagePropertyDNGUniqueCameraModel = static_cast<CFStringRef>(@"UniqueCameraModel");
const CFStringRef kCGImagePropertyDNGLocalizedCameraModel = static_cast<CFStringRef>(@"LocalizedCameraModel");
const CFStringRef kCGImagePropertyDNGCameraSerialNumber = static_cast<CFStringRef>(@"CameraSerialNumber");
const CFStringRef kCGImagePropertyDNGLensInfo = static_cast<CFStringRef>(@"LensInfo");
const CFStringRef kCGImageProperty8BIMLayerNames = static_cast<CFStringRef>(@"LayerNames");
const CFStringRef kCGImagePropertyCIFFDescription = static_cast<CFStringRef>(@"Description");
const CFStringRef kCGImagePropertyCIFFFirmware = static_cast<CFStringRef>(@"Firmware");
const CFStringRef kCGImagePropertyCIFFOwnerName = static_cast<CFStringRef>(@"OwnerName");
const CFStringRef kCGImagePropertyCIFFImageName = static_cast<CFStringRef>(@"ImageName");
const CFStringRef kCGImagePropertyCIFFImageFileName = static_cast<CFStringRef>(@"ImageFileName");
const CFStringRef kCGImagePropertyCIFFReleaseMethod = static_cast<CFStringRef>(@"ReleaseMethod");
const CFStringRef kCGImagePropertyCIFFReleaseTiming = static_cast<CFStringRef>(@"ReleaseTiming");
const CFStringRef kCGImagePropertyCIFFRecordID = static_cast<CFStringRef>(@"RecordID");
const CFStringRef kCGImagePropertyCIFFSelfTimingTime = static_cast<CFStringRef>(@"ReleaseTiming");
const CFStringRef kCGImagePropertyCIFFCameraSerialNumber = static_cast<CFStringRef>(@"CameraSerialNumber");
const CFStringRef kCGImagePropertyCIFFImageSerialNumber = static_cast<CFStringRef>(@"ImageSerialNumber");
const CFStringRef kCGImagePropertyCIFFContinuousDrive = static_cast<CFStringRef>(@"ContinuousDrive");
const CFStringRef kCGImagePropertyCIFFFocusMode = static_cast<CFStringRef>(@"FocusMode");
const CFStringRef kCGImagePropertyCIFFMeteringMode = static_cast<CFStringRef>(@"MeteringMode");
const CFStringRef kCGImagePropertyCIFFShootingMode = static_cast<CFStringRef>(@"ShootingMode");
const CFStringRef kCGImagePropertyCIFFLensMaxMM = static_cast<CFStringRef>(@"LensMaxMM");
const CFStringRef kCGImagePropertyCIFFLensMinMM = static_cast<CFStringRef>(@"LensMinMM");
const CFStringRef kCGImagePropertyCIFFLensModel = static_cast<CFStringRef>(@"LensModel");
const CFStringRef kCGImagePropertyCIFFWhiteBalanceIndex = static_cast<CFStringRef>(@"WhiteBalanceIndex");
const CFStringRef kCGImagePropertyCIFFFlashExposureComp = static_cast<CFStringRef>(@"FlashExposureComp");
const CFStringRef kCGImagePropertyCIFFMeasuredEV = static_cast<CFStringRef>(@"MeasuredEV");
const CFStringRef kCGImagePropertyMakerNikonISOSetting = static_cast<CFStringRef>(@"ISOSetting");
const CFStringRef kCGImagePropertyMakerNikonColorMode = static_cast<CFStringRef>(@"ColorMode");
const CFStringRef kCGImagePropertyMakerNikonQuality = static_cast<CFStringRef>(@"Quality");
const CFStringRef kCGImagePropertyMakerNikonWhiteBalanceMode = static_cast<CFStringRef>(@"WhiteBalanceMode");
const CFStringRef kCGImagePropertyMakerNikonSharpenMode = static_cast<CFStringRef>(@"SharpenMode");
const CFStringRef kCGImagePropertyMakerNikonFocusMode = static_cast<CFStringRef>(@"FocusMode");
const CFStringRef kCGImagePropertyMakerNikonFlashSetting = static_cast<CFStringRef>(@"FlashSetting");
const CFStringRef kCGImagePropertyMakerNikonISOSelection = static_cast<CFStringRef>(@"ISOSelection");
const CFStringRef kCGImagePropertyMakerNikonFlashExposureComp = static_cast<CFStringRef>(@"FlashExposureComp");
const CFStringRef kCGImagePropertyMakerNikonImageAdjustment = static_cast<CFStringRef>(@"ImageAdjustment");
const CFStringRef kCGImagePropertyMakerNikonLensAdapter = static_cast<CFStringRef>(@"LensAdapter");
const CFStringRef kCGImagePropertyMakerNikonLensType = static_cast<CFStringRef>(@"LensType");
const CFStringRef kCGImagePropertyMakerNikonLensInfo = static_cast<CFStringRef>(@"LensInfo");
const CFStringRef kCGImagePropertyMakerNikonFocusDistance = static_cast<CFStringRef>(@"FocusDistance");
const CFStringRef kCGImagePropertyMakerNikonDigitalZoom = static_cast<CFStringRef>(@"DigitalZoom");
const CFStringRef kCGImagePropertyMakerNikonShootingMode = static_cast<CFStringRef>(@"ShootingMode");
const CFStringRef kCGImagePropertyMakerNikonShutterCount = static_cast<CFStringRef>(@"ShutterCount");
const CFStringRef kCGImagePropertyMakerNikonCameraSerialNumber = static_cast<CFStringRef>(@"CameraSerialNumber");
const CFStringRef kCGImagePropertyMakerCanonOwnerName = static_cast<CFStringRef>(@"OwnerName");
const CFStringRef kCGImagePropertyMakerCanonCameraSerialNumber = static_cast<CFStringRef>(@"CameraSerialNumber");
const CFStringRef kCGImagePropertyMakerCanonImageSerialNumber = static_cast<CFStringRef>(@"ImageSerialNumber");
const CFStringRef kCGImagePropertyMakerCanonFlashExposureComp = static_cast<CFStringRef>(@"FlashExposureComp");
const CFStringRef kCGImagePropertyMakerCanonContinuousDrive = static_cast<CFStringRef>(@"ContinuousDrive");
const CFStringRef kCGImagePropertyMakerCanonLensModel = static_cast<CFStringRef>(@"LensModel");
const CFStringRef kCGImagePropertyMakerCanonFirmware = static_cast<CFStringRef>(@"Firmware");
const CFStringRef kCGImagePropertyMakerCanonAspectRatioInfo = static_cast<CFStringRef>(@"AspectRatioInfo");
