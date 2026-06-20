//
//  ScoreCalculator.swift
//  starflower
//
//  Created by 양지성 on 6/19/26.
//

import Foundation

struct ScoreCalculator {

    static func compute(_ i: NightInputs) -> Int {
        let cloud = min(max(i.cloud, 0), 100)
        let base  = 100 * pow(1 - cloud / 100, 1.5)
        let dHum  = 20 * pow(max(0, (i.humidity - 40) / 60), 1.5)
        let dPm   = 10 * pow(min(max(i.pm25 / 75, 0), 1), 0.8)
        let dWind = 7 * min(max(pow(max(0, (i.wind - 3) / 12), 2), 0), 1)
        let dMoon = 8 * min(max(i.moonIllum, 0), 1) * min(max(i.moonExposure, 0), 1)
        let s = min(max(base - dHum - dPm - dWind - dMoon, 0), 100)
        return Int(s.rounded())
    }

    static func verdict(for score: Int) -> String {
        switch score {
        case 80...100: return "최상의 관측 조건"
        case 60..<80:  return "관측하기 좋아요"
        case 40..<60:  return "그럭저럭 볼 만해요"
        case 20..<40:  return "관측이 어려워요"
        default:       return "오늘은 별 보기 힘들어요"
        }
    }

    static func moonPhaseName(phase: Double) -> String {
        let p = ((phase.truncatingRemainder(dividingBy: 1)) + 1)
                    .truncatingRemainder(dividingBy: 1)
        switch p {
        case ..<0.03, 0.97...: return "삭"
        case ..<0.22:  return "초승달"
        case ..<0.28:  return "상현달"
        case ..<0.47:  return "상현망간의 달"
        case ..<0.53:  return "보름달"
        case ..<0.72:  return "하현망간의 달"
        case ..<0.78:  return "하현달"
        default:       return "그믐달"
        }
    }

    static func pmLabel(for pm: Double) -> String {
        switch pm {
        case ..<15:  return "좋음"
        case ..<35:  return "보통"
        case ..<75:  return "나쁨"
        default:     return "매우 나쁨"
        }
    }

    static func conditionLabel(_ c: SkyCondition) -> String {
        switch c {
        case .clear: return "맑음"
        case .partly: return "구름 조금"
        case .cloudy: return "구름 많음"
        case .overcast: return "흐림"
        case .fog: return "안개"
        case .rain: return "비"
        case .snow: return "눈"
        }
    }
}
