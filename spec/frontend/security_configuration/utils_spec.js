import { augmentFeatures, translateScannerNames } from '~/security_configuration/utils';
import { SCANNER_NAMES_MAP } from '~/security_configuration/components/constants';

describe('augmentFeatures', () => {
  const mockSecurityFeatures = [
    {
      name: 'SAST',
      type: 'SAST',
    },
  ];

  const mockComplianceFeatures = [
    {
      name: 'LICENSE_COMPLIANCE',
      type: 'LICENSE_COMPLIANCE',
    },
  ];

  const mockFeaturesWithSecondary = [
    {
      name: 'DAST',
      type: 'DAST',
      secondary: {
        type: 'DAST PROFILES',
        name: 'DAST PROFILES',
      },
    },
  ];

  const mockInvalidCustomFeature = [
    {
      foo: 'bar',
    },
  ];

  const mockValidCustomFeature = [
    {
      name: 'SAST',
      type: 'SAST',
      customField: 'customvalue',
    },
  ];

  const mockValidCustomFeatureSnakeCase = [
    {
      name: 'SAST',
      type: 'SAST',
      custom_field: 'customvalue',
    },
  ];

  const expectedOutputDefault = {
    augmentedSecurityFeatures: mockSecurityFeatures,
    augmentedComplianceFeatures: mockComplianceFeatures,
  };

  const expectedOutputSecondary = {
    augmentedSecurityFeatures: mockSecurityFeatures,
    augmentedComplianceFeatures: mockFeaturesWithSecondary,
  };

  const expectedOutputCustomFeature = {
    augmentedSecurityFeatures: mockValidCustomFeature,
    augmentedComplianceFeatures: mockComplianceFeatures,
  };

  describe('returns an object with augmentedSecurityFeatures and augmentedComplianceFeatures when', () => {
    it('given an empty array', () => {
      expect(augmentFeatures(mockSecurityFeatures, mockComplianceFeatures, [])).toEqual(
        expectedOutputDefault,
      );
    });

    it('given an invalid populated array', () => {
      expect(
        augmentFeatures(mockSecurityFeatures, mockComplianceFeatures, mockInvalidCustomFeature),
      ).toEqual(expectedOutputDefault);
    });

    it('features have secondary key', () => {
      expect(augmentFeatures(mockSecurityFeatures, mockFeaturesWithSecondary, [])).toEqual(
        expectedOutputSecondary,
      );
    });

    it('given a valid populated array', () => {
      expect(
        augmentFeatures(mockSecurityFeatures, mockComplianceFeatures, mockValidCustomFeature),
      ).toEqual(expectedOutputCustomFeature);
    });
  });

  describe('returns an object with camelcased keys', () => {
    it('given a customfeature in snakecase', () => {
      expect(
        augmentFeatures(
          mockSecurityFeatures,
          mockComplianceFeatures,
          mockValidCustomFeatureSnakeCase,
        ),
      ).toEqual(expectedOutputCustomFeature);
    });
  });
});

describe('translateScannerNames', () => {
  it.each(['', undefined, null, 1, 'UNKNOWN_SCANNER_KEY'])('returns %p as is', (key) => {
    expect(translateScannerNames([key])).toEqual([key]);
  });

  it('returns an empty array if no input is provided', () => {
    expect(translateScannerNames([])).toEqual([]);
  });

  it('returns translated scanner names', () => {
    expect(translateScannerNames(Object.keys(SCANNER_NAMES_MAP))).toEqual(
      Object.values(SCANNER_NAMES_MAP),
    );
  });
});
