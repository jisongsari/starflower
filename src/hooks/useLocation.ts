import { useCallback, useEffect, useState } from "react";
import type { SavedLocation } from "../types";

const KEY = "stargazing.location.v1";

function read(): SavedLocation | null {
  try {
    const raw = localStorage.getItem(KEY);
    if (!raw) return null;
    const v = JSON.parse(raw);
    if (typeof v.latitude === "number" && typeof v.longitude === "number") return v;
    return null;
  } catch {
    return null;
  }
}

// 검색한 위치를 저장해두고, 다음 방문 때도 그대로 복원
export function useLocation() {
  const [location, setLocationState] = useState<SavedLocation | null>(() => read());

  const setLocation = useCallback((loc: SavedLocation) => {
    setLocationState(loc);
    try {
      localStorage.setItem(KEY, JSON.stringify(loc));
    } catch {
      /* 저장 실패는 조용히 무시 */
    }
  }, []);

  // 다른 탭에서 바뀌면 동기화
  useEffect(() => {
    const onStorage = (e: StorageEvent) => {
      if (e.key === KEY) setLocationState(read());
    };
    window.addEventListener("storage", onStorage);
    return () => window.removeEventListener("storage", onStorage);
  }, []);

  return { location, setLocation };
}
