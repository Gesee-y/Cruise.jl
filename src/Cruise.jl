###########################################################################################################################################
######################################################### CRUISE GAME ENGINE ##############################################################
###########################################################################################################################################

module Cruise

export HelloCruise!!

##########################################################################################################################################

using Reexport
using Graphs
using Base.Threads

include("..\\..\\AssetCrates.jl\\src\\AssetCrates.jl")
@reexport using EventNotifiers
@reexport using NodeTree
@reexport using GDMathLib
@reexport using .AssetCrates

include("events.jl")
include("tempstorage.jl")

@reexport using .TemporaryStorage
include(joinpath("plugin", "plugin.jl"))
include("utilities.jl")
include("App.jl")
include("object.jl")
include("game_loop.jl")
include("writer.jl")

text_en = [
	"{speed:0.2}Everything begins somewhere.{pause:4}",
    "No dream comes from nowhere.{pause:4}",
    "We are all searching for a new beginning.{pause:3}",
    "{speed:0.3}A new land where flowers bloom once more.{pause:4}",
    "{speed:0.1}Behind these shadowy clouds of darkness{pause:1}.{pause:1}.{pause:1}.{pause:3}",
    "{speed:0.2}Lies a breathtaking field of success.{pause:5}",
    "{speed:0.1}Let go of the fear that binds your heart.{pause:3}",
    "Follow the shining stars of hope.{pause:3}",
    "{speed:0.2}And even if there's nothing waiting tomorrow{pause:1}.{pause:1}.{pause:1}.{pause:3}",
    "{speed:0.15}I’ll still be grateful to have been part of your journey.{pause:4}",
    "{speed:0.1}Sail away.{pause:2}",
    "Write your own story.{pause:2}",
    "Break the rules.{pause:2}",
    "{speed:0.15}And most importantly{pause:1}.{pause:1}.{pause:1}.{pause:4}",
    "{speed:0.25}Never let them forget your Cruise.{pause:5}",
]

text_fr = [
    "{speed:0.2}Tout commence quelque part.{pause:4}",
    "Aucun rêve ne naît de nulle part.{pause:4}",
    "Nous cherchons tous un nouveau départ.{pause:3}",
    "{speed:0.3}Une terre nouvelle où les fleurs renaissent.{pause:4}",
    "{speed:0.1}Derrière ces sombres nuages de ténèbres{pause:1}.{pause:1}.{pause:1}.{pause:3}",
    "{speed:0.2}S’étend un champ de succès éblouissant.{pause:5}",
    "{speed:0.1}Libère-toi de la peur qui enchaîne ton cœur.{pause:3}",
    "Suis les étoiles brillantes de l’espoir.{pause:3}",
    "{speed:0.2}Et même s’il n’y a rien demain{pause:1}.{pause:1}.{pause:1}.{pause:3}",
    "{speed:0.15}Je serai tout de même reconnaissant d’avoir partagé ton voyage.{pause:4}",
    "{speed:0.1}Lève l’ancre.{pause:2}",
    "Écris ta propre histoire.{pause:2}",
    "Brise les règles.{pause:2}",
    "{speed:0.15}Et surtout{pause:1}.{pause:1}.{pause:1}.{pause:4}",
    "{speed:0.25}Ne les laisse jamais oublier ta Croisière.{pause:5}",
]

text_hi = [
    "{speed:0.2}Har project kahin na kahin se shuru hota hai.{pause:3}",
    "Koi bhi code bina maksad ke nahi likha jaata.{pause:3}",
    "Tumne abhi pehla kadam uthaya hai.{pause:2}",
    "{speed:0.3}Swagat hai tumhari naye creation ke zameen par.{pause:4}",
    "{speed:0.1}Galtiyon, shak, aur lambī rāt ke paar{pause:1}.{pause:1}.{pause:1}.{pause:3}",
    "{speed:0.2}Ek anant sambhavnāon ka kshetra hai.{pause:4}",
    "{speed:0.1}Dar ko chhodo jo tumhe roke hue hai.{pause:2}",
    "Apne vision par bharosa rakho.{pause:2}",
    "{speed:0.2}Chahe safalta kal na aaye{pause:1}.{pause:1}.{pause:1}.{pause:3}",
    "{speed:0.15}Shuruaat hi sabse badi jeet hai.{pause:4}",
    "{speed:0.1}Shuru karo.{pause:2}",
    "Apna engine likho.{pause:2}",
    "Apni raah banao.{pause:2}",
    "{speed:0.15}Aur sabse zaruri baat{pause:1}.{pause:1}.{pause:1}.{pause:4}",
    "{speed:0.25}Kabhi mat bhoolna: yeh tumhara Cruise hai.{pause:5}",
    "{speed:0.3}Namaste, Cruise!!{pause:3}"
]

text_zh = [
    "{speed:0.2}每一个项目都有一个起点。{pause:3}",
    "每一行代码，都是出于某种信念。{pause:3}",
    "你刚迈出了第一步。{pause:2}",
    "{speed:0.3}欢迎来到你的创造新世界。{pause:4}",
    "{speed:0.1}在无数错误、怀疑和不眠夜之后{pause:1}.{pause:1}.{pause:1}.{pause:3}",
    "{speed:0.2}隐藏着无限可能的原野。{pause:4}",
    "{speed:0.1}放下束缚你前进的恐惧。{pause:2}",
    "相信你的视野。{pause:2}",
    "{speed:0.2}即使明天没有结果{pause:1}.{pause:1}.{pause:1}.{pause:3}",
    "{speed:0.15}开始本身就是一种创造。{pause:4}",
    "{speed:0.1}启航吧。{pause:2}",
    "写下你的引擎。{pause:2}",
    "走出你的道路。{pause:2}",
    "{speed:0.15}最重要的是{pause:1}.{pause:1}.{pause:1}.{pause:4}",
    "{speed:0.25}不要让人忘记你的 Cruise。{pause:5}",
    "{speed:0.3}你好，Cruise！！{pause:3}"
]

text_ja = [
    "{speed:0.2}すべてのプロジェクトには始まりがある。{pause:3}",
    "コードは意味なしに生まれない。{pause:3}",
    "君は今、最初の一歩を踏み出した。{pause:2}",
    "{speed:0.3}創造の新しい大地へようこそ。{pause:4}",
    "{speed:0.1}ミスや不安、終わらない夜のその先に{pause:1}.{pause:1}.{pause:1}.{pause:3}",
    "{speed:0.2}無限の可能性が広がっている。{pause:4}",
    "{speed:0.1}その恐れを手放せ。{pause:2}",
    "自分のビジョンを信じろ。{pause:2}",
    "{speed:0.2}たとえ明日結果が出なくても{pause:1}.{pause:1}.{pause:1}.{pause:3}",
    "{speed:0.15}始めることこそ、最大の一歩だ。{pause:4}",
    "{speed:0.1}さあ、旅立とう。{pause:2}",
    "自分のエンジンを書こう。{pause:2}",
    "自分の道を切り開こう。{pause:2}",
    "{speed:0.15}そして何よりも{pause:1}.{pause:1}.{pause:1}.{pause:4}",
    "{speed:0.25}君の Cruise を、誰にも忘れさせるな。{pause:5}",
    "{speed:0.3}こんにちは、Cruise！！{pause:3}"
]

const LOCALES = Dict(
    :en => text_en,
    :fr => text_fr,
    #:es => text_es,
    :hi => text_hi,
    :zh => text_zh,
    :ja => text_ja
)

"""
    HelloCruise!!(locale=:en)

Displays the introductory narrative for the Cruise game engine in the specified locale.
- `locale`: Symbol indicating the language (e.g., `:en`, `:fr`, `:hi`, `:zh`, `:ja`).
"""
function HelloCruise!!(locale=:en)
    !haskey(LOCALES, locale) && (locale = :en)
	writer = TextWriter(LOCALES[locale])
	write_text(writer)

    println("Hello, Cruise!!")
end

end #module