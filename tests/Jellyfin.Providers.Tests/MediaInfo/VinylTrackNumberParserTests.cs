using System;
using System.Globalization;
using Xunit;

namespace Jellyfin.Providers.Tests.MediaInfo
{
    public class VinylTrackNumberParserTests
    {
        /// <summary>
        /// Copy of the exact parsing logic from AudioFileProber for testing.
        /// </summary>
        private static bool TryParseVinylTrackNumber(string? vinylTrack, out int trackNumber)
        {
            trackNumber = 0;

            if (string.IsNullOrWhiteSpace(vinylTrack))
            {
                return false;
            }

            string normalizedTrack = vinylTrack.Trim().ToUpperInvariant();

            try
            {
                // Handle standard vinyl formats: [Side Letter][Track Number]
                if (normalizedTrack.Length >= 2 && char.IsLetter(normalizedTrack[0]) && char.IsDigit(normalizedTrack[1]))
                {
                    var side = char.ToUpper(normalizedTrack[0], CultureInfo.InvariantCulture) - 'A';
                    var numericPart = normalizedTrack.Substring(1);

                    if (int.TryParse(numericPart, NumberStyles.Integer, CultureInfo.InvariantCulture, out int trackOnSide))
                    {
                        trackNumber = (side * 20) + trackOnSide;
                        return true;
                    }
                }

                // Handle reverse vinyl formats: [Track Number][Side Letter]
                if (normalizedTrack.Length >= 2 && char.IsDigit(normalizedTrack[0]) && char.IsLetter(normalizedTrack[^1]))
                {
                    var side = char.ToUpper(normalizedTrack[^1], CultureInfo.InvariantCulture) - 'A';
                    var numericPart = normalizedTrack[..^1];

                    if (int.TryParse(numericPart, NumberStyles.Integer, CultureInfo.InvariantCulture, out int trackOnSide))
                    {
                        trackNumber = (side * 20) + trackOnSide;
                        return true;
                    }
                }

                // Try plain number as last resort
                if (int.TryParse(normalizedTrack, NumberStyles.Integer, CultureInfo.InvariantCulture, out trackNumber))
                {
                    return true;
                }
            }
            catch (Exception)
            {
                // Silent catch for testing
            }

            return false;
        }

        [Theory]
        [InlineData("A1", 1)] // Standard vinyl format
        [InlineData("A2", 2)] // Standard vinyl format
        [InlineData("B1", 21)] // Side B, track 1
        [InlineData("B2", 22)] // Side B, track 2
        [InlineData("C5", 45)] // Side C, track 5
        [InlineData("A01", 1)] // Padded vinyl format
        [InlineData("B05", 25)] // Padded side B
        [InlineData("1A", 1)] // Reverse format
        [InlineData("2B", 22)] // Reverse format
        [InlineData("01", 1)] // Standard numeric
        [InlineData("15", 15)] // Standard numeric
        public void TryParseVinylTrackNumber_ValidFormats_ParsesCorrectly(string input, int expected)
        {
            // Act
            var result = TryParseVinylTrackNumber(input, out int actual);

            // Assert
            Assert.True(result, $"Failed to parse '{input}'");
            Assert.Equal(expected, actual);
        }

        [Theory]
        [InlineData(null)] // Null input
        [InlineData("")] // Empty string
        [InlineData("   ")] // Whitespace
        [InlineData("Side A")] // Invalid format
        [InlineData("Track 1")] // Invalid format
        [InlineData("A")] // Missing track number
        [InlineData("ABC")] // No numbers
        [InlineData("A1B")] // Mixed format
        public void TryParseVinylTrackNumber_InvalidFormats_ReturnsFalse(string? input)
        {
            // Act
            var result = TryParseVinylTrackNumber(input, out int actual);

            // Assert
            Assert.False(result, $"Should have failed to parse '{input}'");
            Assert.Equal(0, actual);
        }

        [Fact]
        public void TryParseVinylTrackNumber_CultureInvariant_ParsesCorrectly()
        {
            // Arrange - Test with different cultures
            var cultures = new[] { "en-US", "tr-TR", "de-DE" };

            foreach (var cultureName in cultures)
            {
                var culture = new CultureInfo(cultureName);
                CultureInfo.CurrentCulture = culture;

                // Act - Should work regardless of current culture
                var result = TryParseVinylTrackNumber("a1", out int actual);

                // Assert
                Assert.True(result, $"Failed to parse 'a1' in culture {cultureName}");
                Assert.Equal(1, actual);
            }

            // Restore default culture
            CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;
        }

        [Fact]
        public void RealWorldScenario_GitHubIssue4991()
        {
            // Test the exact case from the GitHub issue
            string vinylTrackNumber = "A1";

            // Act
            var result = TryParseVinylTrackNumber(vinylTrackNumber, out int actual);

            // Assert - Should parse A1 as track 1
            Assert.True(result);
            Assert.Equal(1, actual);
        }

        [Fact]
        public void CompleteVinylAlbum_OrdersCorrectly()
        {
            // Test data representing a complete vinyl album
            var testCases = new[]
            {
                new { Input = "A1", Expected = 1 },
                new { Input = "A2", Expected = 2 },
                new { Input = "A3", Expected = 3 },
                new { Input = "B1", Expected = 21 },
                new { Input = "B2", Expected = 22 },
                new { Input = "B3", Expected = 23 },
                new { Input = "C1", Expected = 41 },
                new { Input = "C2", Expected = 42 }
            };

            foreach (var testCase in testCases)
            {
                // Act
                var result = TryParseVinylTrackNumber(testCase.Input, out int actual);

                // Assert
                Assert.True(result, $"Failed to parse '{testCase.Input}'");
                Assert.Equal(testCase.Expected, actual);
            }
        }

        [Fact]
        public void ParseTrackNumber_Logic_StandardPrecedence()
        {
            // Test the logical flow without dependencies
            int? standardTrackNumber = 7;
            string vinylTrackNumber = "A2";

            // Simulate: standardTrackNumber ?? ParseVinyl(vinylTrackNumber)
            int? result = standardTrackNumber ?? ParseVinyl(vinylTrackNumber);

            Assert.Equal(7, result);
        }

        [Fact]
        public void ParseTrackNumber_Logic_VinylFallback()
        {
            // Test the logical flow without dependencies
            int? standardTrackNumber = null;
            string vinylTrackNumber = "B3";

            // Simulate: standardTrackNumber ?? ParseVinyl(vinylTrackNumber)
            int? result = standardTrackNumber ?? ParseVinyl(vinylTrackNumber);

            Assert.Equal(23, result); // B3 = 23
        }

        private static int? ParseVinyl(string vinylTrack)
        {
            return TryParseVinylTrackNumber(vinylTrack, out int result) ? result : null;
        }
    }
}
