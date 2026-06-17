import { useEffect, useRef, useState } from "react";
import { searchLocations } from "../api/geocode";
import type { GeoResult, SavedLocation } from "../types";

interface SearchOverlayProps {
  open: boolean;
  onClose: () => void;
  onSelect: (loc: SavedLocation) => void;
  dismissable: boolean; // 저장된 위치가 없으면 닫기 불가
}

export default function SearchOverlay({ open, onClose, onSelect, dismissable }: SearchOverlayProps) {
  const [query, setQuery] = useState("");
  const [results, setResults] = useState<GeoResult[]>([]);
  const [loading, setLoading] = useState(false);
  const [err, setErr] = useState<string | null>(null);
  const inputRef = useRef<HTMLInputElement>(null);
  const lastSelect = useRef(0);

  // 결과 선택 (누르는 즉시 처리해 한 번에 선택되도록)
  const choose = (r: GeoResult) => {
    const now = Date.now();
    if (now - lastSelect.current < 600) return; // 중복 호출 방지
    lastSelect.current = now;
    onSelect({
      name: r.name,
      admin1: r.admin1,
      country: r.country,
      latitude: r.latitude,
      longitude: r.longitude,
    });
  };

  useEffect(() => {
    if (open) setTimeout(() => inputRef.current?.focus(), 80);
  }, [open]);

  // 디바운스 검색
  useEffect(() => {
    const q = query.trim();
    if (q.length < 2) {
      setResults([]);
      setErr(null);
      setLoading(false);
      return;
    }
    setLoading(true);
    const id = setTimeout(async () => {
      try {
        const r = await searchLocations(q);
        setResults(r);
        setErr(r.length === 0 ? "검색 결과가 없어요. 다른 이름으로 찾아보세요." : null);
      } catch {
        setErr("검색에 실패했어요. 잠시 후 다시 시도해주세요.");
      } finally {
        setLoading(false);
      }
    }, 500);
    return () => clearTimeout(id);
  }, [query]);

  if (!open) return null;

  return (
    <div
      className="search-overlay"
      role="dialog"
      aria-modal="true"
      // 입력창 외 영역을 눌러도 포커스가 풀리지 않게 (한글 IME 커밋·리스트 사라짐 방지)
      onMouseDown={(e) => {
        if (e.target !== inputRef.current) e.preventDefault();
      }}
    >
      <div className="search-panel">
        <div className="search-bar">
          <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
            <circle cx="11" cy="11" r="7" />
            <path d="m20 20-3.2-3.2" />
          </svg>
          <input
            ref={inputRef}
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="도시 또는 지역 검색"
            autoComplete="off"
            spellCheck={false}
          />
          {dismissable && (
            <button className="search-cancel" onClick={onClose}>
              취소
            </button>
          )}
        </div>

        <div className="search-results">
          {loading && <div className="search-hint">검색 중…</div>}
          {err && !loading && <div className="search-hint">{err}</div>}
          {!query.trim() && !loading && (
            <div className="search-hint">관측할 지역을 검색해 보세요. 검색한 위치는 자동으로 저장돼요.</div>
          )}
          {query.trim().length === 1 && !loading && (
            <div className="search-hint">두 글자 이상 입력해 주세요.</div>
          )}
          {results.map((r) => (
            <button
              key={r.id}
              className="search-result"
              // 누르는 즉시(재렌더 경쟁 이전에) 선택
              onMouseDown={() => choose(r)}
              onClick={() => choose(r)} // 키보드(Enter) 접근성용
            >
              <span className="result-name">{r.name}</span>
              <span className="result-meta">
                {[r.admin1, r.country].filter(Boolean).join(", ")}
              </span>
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}
