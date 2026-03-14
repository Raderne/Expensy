import React, { useRef, useState } from 'react';
import { Dimensions, FlatList, StatusBar, StyleSheet, Text, TouchableOpacity, View, ViewToken } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import * as SecureStore from 'expo-secure-store';
import { TrendingUp, BarChart2, Wallet } from 'lucide-react-native';
import { Colors } from '@/constants/colors';

const ONBOARDING_KEY = 'expensy_onboarding_done';
const { width: SCREEN_WIDTH } = Dimensions.get('window');

// ---------------------------------------------------------------------------
// Slide data
// ---------------------------------------------------------------------------
interface SlideData {
  id: string;
  title: string;
  titleAccent: string;
  subtitle: string;
  bgColors: readonly [string, string];
  buttonColor: string;
  buttonLabel: string;
  buttonTextDark?: boolean;
  IllustrationIcon: React.ComponentType<{ size: number; color: string; strokeWidth: number }>;
  illustrationBg: string;
}

const slides: SlideData[] = [
  {
    id: '1',
    title: 'Welcome to',
    titleAccent: 'Expensy',
    subtitle: 'Take control of your finances effortlessly.',
    bgColors: ['#1A0A2E', '#0A0A0F'],
    buttonColor: Colors.purple[500],
    buttonLabel: 'Next',
    IllustrationIcon: Wallet,
    illustrationBg: 'rgba(176,78,255,0.15)',
  },
  {
    id: '2',
    title: 'Automatic',
    titleAccent: 'Logging',
    subtitle: 'We automatically group your expenses by date, saving you time every day.',
    bgColors: ['#0A1F0E', '#061209'],
    buttonColor: Colors.mint[500],
    buttonLabel: 'Next  →',
    buttonTextDark: true,
    IllustrationIcon: TrendingUp,
    illustrationBg: 'rgba(0,229,160,0.12)',
  },
  {
    id: '3',
    title: 'Smart',
    titleAccent: 'Insights',
    subtitle: 'Visualize your spending habits with beautiful, easy-to-read analytics.',
    bgColors: ['#060D1A', '#0A1229'],
    buttonColor: Colors.info,
    buttonLabel: 'Get Started',
    IllustrationIcon: BarChart2,
    illustrationBg: 'rgba(59,130,246,0.12)',
  },
];

// ---------------------------------------------------------------------------
// Dot indicator
// ---------------------------------------------------------------------------
function Dots({ activeIndex }: { activeIndex: number }) {
  return (
    <View style={dotStyles.row}>
      {slides.map((s, i) => (
        <View key={s.id} style={[dotStyles.dot, i === activeIndex ? dotStyles.dotActive : dotStyles.dotInactive]} />
      ))}
    </View>
  );
}

const dotStyles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    gap: 6,
    justifyContent: 'center',
    marginBottom: 24,
  },
  dot: {
    height: 8,
    borderRadius: 4,
  },
  dotActive: {
    width: 24,
    backgroundColor: Colors.text.primary,
  },
  dotInactive: {
    width: 8,
    backgroundColor: Colors.border.strong,
  },
});

// ---------------------------------------------------------------------------
// Single slide
// ---------------------------------------------------------------------------
function Slide({ item }: { item: SlideData }) {
  const { IllustrationIcon, illustrationBg } = item;

  return (
    <View style={[slideStyles.slide, { width: SCREEN_WIDTH }]}>
      {/* Illustration placeholder */}
      <View style={[slideStyles.illustration, { backgroundColor: illustrationBg }]}>
        <IllustrationIcon size={72} color={Colors.text.primary} strokeWidth={1.2} />
      </View>

      {/* Text */}
      <View style={slideStyles.textBlock}>
        <View style={slideStyles.titleRow}>
          <Text style={slideStyles.titleBase}>{item.title} </Text>
          <Text style={slideStyles.titleAccent}>{item.titleAccent}</Text>
        </View>
        <Text style={slideStyles.subtitle}>{item.subtitle}</Text>
      </View>
    </View>
  );
}

const slideStyles = StyleSheet.create({
  slide: {
    alignItems: 'center',
    paddingHorizontal: 32,
  },
  illustration: {
    width: SCREEN_WIDTH * 0.65,
    aspectRatio: 1,
    borderRadius: 32,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 48,
  },
  textBlock: {
    alignItems: 'center',
  },
  titleRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'center',
    marginBottom: 16,
  },
  titleBase: {
    fontSize: 34,
    fontWeight: '800',
    color: Colors.text.primary,
    letterSpacing: -0.5,
  },
  titleAccent: {
    fontSize: 34,
    fontWeight: '800',
    color: Colors.purple[400],
    letterSpacing: -0.5,
  },
  subtitle: {
    fontSize: 16,
    color: Colors.text.secondary,
    textAlign: 'center',
    lineHeight: 24,
  },
});

// ---------------------------------------------------------------------------
// Main onboarding screen
// ---------------------------------------------------------------------------
export default function OnboardingScreen() {
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const flatListRef = useRef<FlatList<SlideData>>(null);
  const [activeIndex, setActiveIndex] = useState(0);

  const currentSlide = slides[activeIndex];

  const markDoneAndNavigate = async () => {
    await SecureStore.setItemAsync(ONBOARDING_KEY, 'true');
    router.replace('/(auth)/login');
  };

  const handleNext = async () => {
    if (activeIndex < slides.length - 1) {
      const nextIndex = activeIndex + 1;
      flatListRef.current?.scrollToIndex({ index: nextIndex, animated: true });
      setActiveIndex(nextIndex);
    } else {
      await markDoneAndNavigate();
    }
  };

  const handleSkip = async () => {
    await markDoneAndNavigate();
  };

  const onViewableItemsChanged = useRef(({ viewableItems }: { viewableItems: ViewToken[] }) => {
    if (viewableItems.length > 0 && viewableItems[0].index != null) {
      setActiveIndex(viewableItems[0].index);
    }
  }).current;

  const viewabilityConfig = useRef({ itemVisiblePercentThreshold: 50 }).current;

  return (
    <View style={styles.root}>
      <StatusBar barStyle='light-content' />

      {/* Dynamic background gradient that follows active slide */}
      <LinearGradient colors={currentSlide.bgColors} style={StyleSheet.absoluteFill} />

      {/* Skip button — visible on slides 2+ */}
      <View style={[styles.topBar, { paddingTop: insets.top + 12 }]}>
        <View style={styles.topBarSpacer} />
        {activeIndex > 0 ? (
          <TouchableOpacity onPress={handleSkip} activeOpacity={0.7} accessibilityLabel='Skip onboarding' accessibilityRole='button'>
            <Text style={styles.skipText}>Skip</Text>
          </TouchableOpacity>
        ) : (
          <View style={styles.topBarSpacer} />
        )}
      </View>

      {/* Slides */}
      <FlatList
        ref={flatListRef}
        data={slides}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => <Slide item={item} />}
        horizontal
        pagingEnabled
        scrollEnabled={false}
        showsHorizontalScrollIndicator={false}
        onViewableItemsChanged={onViewableItemsChanged}
        viewabilityConfig={viewabilityConfig}
        style={styles.flatList}
        contentContainerStyle={styles.flatListContent}
      />

      {/* Bottom controls */}
      <View style={[styles.bottomControls, { paddingBottom: insets.bottom + 24 }]}>
        <Dots activeIndex={activeIndex} />

        <TouchableOpacity
          style={[styles.nextButton, { backgroundColor: currentSlide.buttonColor }]}
          onPress={handleNext}
          activeOpacity={0.85}
          accessibilityRole='button'
          accessibilityLabel={currentSlide.buttonLabel}
        >
          <Text style={[styles.nextButtonLabel, currentSlide.buttonTextDark === true && styles.nextButtonLabelDark]}>{currentSlide.buttonLabel}</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: Colors.bg.base,
  },
  topBar: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    paddingHorizontal: 24,
    paddingBottom: 8,
  },
  topBarSpacer: {
    width: 40,
  },
  skipText: {
    fontSize: 15,
    color: Colors.text.secondary,
    fontWeight: '500',
  },
  flatList: {
    flex: 1,
  },
  flatListContent: {
    alignItems: 'center',
  },
  bottomControls: {
    paddingHorizontal: 24,
    alignItems: 'center',
  },
  nextButton: {
    width: '100%',
    paddingVertical: 18,
    borderRadius: 9999,
    alignItems: 'center',
    justifyContent: 'center',
  },
  nextButtonLabel: {
    fontSize: 16,
    fontWeight: '700',
    color: Colors.text.primary,
    letterSpacing: 0.3,
  },
  nextButtonLabelDark: {
    color: Colors.text.inverse,
  },
});
